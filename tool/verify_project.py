#!/usr/bin/env python3
"""Fail-fast project integrity check (no Flutter needed). Run from the project root.

Checks that:
  1. every relative / package:lunanest import resolves to a file that exists,
  2. every project-defined class/function/provider a file uses is imported (directly) from the file that defines it,
  3. every `show` name exists in the imported file,
  4. every `const Foo(...)` of a project class has a const constructor,
  5. every CategoryStyle member that is used exists,
  6. asset paths referenced by assets/catalog.json exist (when assets/audio has been generated).
Exit code 1 with a clear message if anything is wrong, e.g. a partial update zip was unpacked over an older project.
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
os.chdir(ROOT)
errors = []

files = sorted(glob.glob("lib/**/*.dart", recursive=True) + glob.glob("test/**/*.dart", recursive=True)
               + glob.glob("integration_test/**/*.dart", recursive=True))


def strip(src):
    src = re.sub(r"'''.*?'''", "''", src, flags=re.S)
    src = re.sub(r'""".*?"""', '""', src, flags=re.S)
    src = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", src)
    src = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', src)
    return re.sub(r"//.*", "", src)


def resolve(frm, target):
    if target.startswith("package:lunanest/"):
        return os.path.normpath("lib/" + target[len("package:lunanest/"):])
    if ":" not in target:  # relative path, with or without leading "./" or "../"
        return os.path.normpath(os.path.join(os.path.dirname(frm), target))
    return None  # dart: or an external package


raw = {f: open(f, encoding="utf-8").read() for f in files}
code = {f: strip(s) for f, s in raw.items()}

DECL = [
    re.compile(r"^(?:abstract\s+|sealed\s+|final\s+|base\s+)?(?:class|enum|mixin|typedef)\s+([A-Za-z]\w*)", re.M),
    re.compile(r"^(?:[\w<>?,\[\]]+\s+)+?([a-z]\w*)\s*\(", re.M),
    re.compile(r"^(?:final|const|var)\s+(?:[\w<>?,\[\] ]+\s+)?([a-zA-Z]\w*)\s*=", re.M),
]
SKIP = {"main", "if", "for", "while", "switch", "return", "import", "export", "part"}
declared = {}  # file -> set(symbols)
for f in files:
    if not f.startswith("lib/"):
        continue
    syms = set()
    for rx in DECL:
        for m in rx.finditer(code[f]):
            n = m.group(1)
            if n not in SKIP and not n.startswith("_"):
                syms.add(n)
    declared[f] = syms

owner = {}
for f, syms in declared.items():
    for s in syms:
        owner.setdefault(s, set()).add(f)

IMPORT = re.compile(r"""^(import|export)\s+['"]([^'"]+)['"]([^;]*);""", re.M)
for f in files:
    imports = {}
    for m in IMPORT.finditer(raw[f]):
        t = resolve(f, m.group(2))
        if t is None:
            continue
        if not os.path.exists(t):
            errors.append(f"{f}: import '{m.group(2)}' -> MISSING FILE {t}")
            continue
        imports[t] = m.group(3)
        sh = re.search(r"\bshow\s+([\w,\s]+)", m.group(3))
        if sh and t in declared:
            for name in [x.strip() for x in sh.group(1).split(",") if x.strip()]:
                if name not in declared[t]:
                    errors.append(f"{f}: 'show {name}' but {t} does not declare it")
    tokens = set(re.findall(r"\b[A-Za-z_]\w*\b", code[f]))
    own = declared.get(f, set())
    for tok in tokens:
        if tok in own or tok not in owner:
            continue
        defs = owner[tok]
        if not any(d in imports for d in defs):
            errors.append(f"{f}: uses '{tok}' (defined in {', '.join(sorted(defs))}) but does not import it")

# const constructors
for f in files:
    for m in re.finditer(r"\bconst\s*\[?\s*([A-Z]\w*)\s*\(", code[f]):
        cls = m.group(1)
        if cls in owner:
            ok = any(re.search(r"\bconst\s+" + cls + r"\s*\(", code[d]) for d in owner[cls])
            if not ok:
                errors.append(f"{f}: 'const {cls}(...)' but {cls} has no const constructor")

# CategoryStyle members
cs_file = "lib/core/category_style.dart"
if os.path.exists(cs_file):
    fields = set(re.findall(r"final\s+[\w<>]+\s+(\w+);", code[cs_file]))
    for f in files:
        for m in re.finditer(r"CategoryStyle\.of\([^)]*\)\.(\w+)", code[f]):
            if m.group(1) not in fields:
                errors.append(f"{f}: CategoryStyle.{m.group(1)} is not defined (fields: {sorted(fields)})")

# named arguments of project constructors (typos / missing parameters)
def match_close(text, i, open_ch, close_ch):
    depth = 0
    for k in range(i, len(text)):
        c = text[k]
        if c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
            if depth == 0:
                return k
    return -1


ctor_params = {}  # class -> set(named params)
for f in declared:
    for m in re.finditer(r"\b(?:const\s+)?([A-Z]\w*)\s*\(\s*\{", code[f]):
        cls = m.group(1)
        if cls not in declared[f]:
            continue
        brace = code[f].index("{", m.end() - 1)
        end = match_close(code[f], brace, "{", "}")
        body = code[f][brace + 1:end]
        names = set(re.findall(r"(?:this|super)\.(\w+)", body))
        names |= set(re.findall(r"[\w>?\]]\s+(\w+)\s*(?:=|,|$)", body.strip() + ","))
        ctor_params[cls] = names

for f in files:
    c = code[f]
    for m in re.finditer(r"(?<![\w.])([A-Z]\w*)\s*\(", c):
        cls = m.group(1)
        if cls not in ctor_params:
            continue
        # skip the declaration itself and named constructors
        if re.match(r"\s*\{", c[m.end():]) and cls in declared.get(f, set()) and re.search(r"(?:class\s+\w+[^{]*\{[^}]*)$", c[:m.start()][-200:]) is None and False:
            continue
        close = match_close(c, m.end() - 1, "(", ")")
        if close < 0:
            continue
        args = c[m.end():close]
        depth, cur, top = 0, "", []
        for ch in args:
            if ch in "([{":
                depth += 1
            elif ch in ")]}":
                depth -= 1
            if ch == "," and depth == 0:
                top.append(cur)
                cur = ""
            else:
                cur += ch
        top.append(cur)
        for a in top:
            nm = re.match(r"\s*(\w+)\s*:(?!:)", a)
            if nm and nm.group(1) not in ctor_params[cls] and "{" not in a.split(":")[0]:
                errors.append(f"{f}: {cls}(...) has no parameter named '{nm.group(1)}' (has: {sorted(ctor_params[cls])})")

# every catalog sound must have a generator entry (and vice versa) in tool/generate_audio.py
if os.path.exists("assets/catalog.json") and os.path.exists("tool/generate_audio.py"):
    gen = open("tool/generate_audio.py", encoding="utf-8").read()
    registry = gen[gen.index("SOUNDS = {"):]
    registry = registry[:registry.index("\n}\n")]
    gen_ids = set(re.findall(r'^\s*"(\w+)":\s*\(', registry, re.M))
    cat = json.load(open("assets/catalog.json"))
    cat_ids = [x["id"] for x in cat["sounds"]]
    if len(cat_ids) != len(set(cat_ids)):
        errors.append("assets/catalog.json has duplicate sound ids")
    for i in cat_ids:
        if i not in gen_ids:
            errors.append(f"catalog sound '{i}' has no generator entry in tool/generate_audio.py")
    for i in sorted(gen_ids - set(cat_ids)):
        errors.append(f"generator makes '{i}' but it is not in assets/catalog.json")
    cats = {c["id"] for c in cat["categories"]}
    for x in cat["sounds"]:
        if x["category"] not in cats:
            errors.append(f"sound '{x['id']}' uses unknown category '{x['category']}'")
        if x.get("premium"):
            errors.append(f"sound '{x['id']}' is marked premium (all sounds must stay free)")
        if x.get("asset") != f"assets/audio/{x['id']}.wav":
            errors.append(f"sound '{x['id']}' asset path should be assets/audio/{x['id']}.wav")

# catalog assets
if os.path.exists("assets/catalog.json") and os.path.isdir("assets/audio") and glob.glob("assets/audio/*.wav"):
    for s in json.load(open("assets/catalog.json"))["sounds"]:
        a = s.get("asset")
        if a and not os.path.exists(a):
            errors.append(f"catalog sound '{s['id']}' points at missing asset {a}")

if errors:
    print("PROJECT VERIFICATION FAILED:\n  " + "\n  ".join(errors))
    print("\nIf files are missing, a partial update zip was probably unpacked over an older project. "
          "Upload the COMPLETE project zip (lunanest_full.zip, renamed lunanest.zip) and run the unpack workflow again.")
    sys.exit(1)
print(f"Project verification passed: {len(files)} Dart files, imports/symbols/const/CategoryStyle all consistent.")
