# Building LunaNest from an Android phone only

Everything runs in GitHub's cloud. You need a free GitHub account and a mobile browser.

## One-time setup (about 15 minutes)

1. **Create a repository.** github.com → New repository → name `lunanest` → *Private* → check "Add a README" → Create.
2. **Add the unpack workflow.** In the repo: *Add file → Create new file*. In the name box type
   `.github/workflows/unpack.yml` (typing `/` creates folders). Paste the contents of `ci/unpack.yml`
   (shown in the chat / included in the zip) and tap *Commit changes*.
3. **Upload the project zip.** *Add file → Upload files* → choose `lunanest.zip` (do NOT unzip it) → Commit.
   The "Unpack project" workflow runs (Actions tab) and commits the real project files within ~30 seconds.
4. **Activate the build workflow.** In the repo open `ci/android.yml` → pencil (edit) icon → change the file
   name at the top to `.github/workflows/android.yml` → Commit. (Optionally do the same for `ci/ios.yml`.)
   The workflow files must be moved by you because GitHub does not allow automated pushes into `.github/workflows`.
5. **Run the build.** *Actions → Android build → Run workflow* (leave "publish pre-release" on).
   First run takes ~10–15 minutes.
6. **Install.** When it is green, open *Releases* → latest "LunaNest build N" → tap `app-release.apk` → open
   the downloaded file → allow "Install unknown apps" for your browser when asked.
   (Alternative: the run page's *Artifacts* section contains `lunanest-apk.zip`.)

## When the build fails (expected on a first run)
This code was written without a Flutter compiler, so compile errors are plausible. Open the failed run →
the red step → copy the error lines → paste them to Claude with "fix this". Replace the changed files:
GitHub web → open the file → pencil → select all → paste → Commit. (`github.dev` — press `.` on the repo page —
is a full VS Code editor in the browser; also works on mobile in desktop-site mode.)

## Secrets (Settings → Secrets and variables → Actions → New repository secret)
| Secret | Purpose |
|---|---|
| `REVENUECAT_ANDROID_KEY` | RevenueCat *public* Android SDK key (`goog_...`). Leave unset → app runs free-only. |
| `SUPPORT_EMAIL` | Shown on the Support screen. |
Never put these in source files.

## Limits to know before choosing this workflow
- Free GitHub accounts include a monthly Actions quota (private repos); Linux builds are cheap, macOS minutes
  cost much more. Check current quotas.
- You can **install and test on your Android phone** this way. You cannot test iOS at all without an iPhone.
- **iOS release needs** an Apple Developer account (paid) plus macOS CI. The `ios.yml` workflow only proves the code
  compiles (no signing). Signing/upload is described in APP_STORE_RELEASE_CHECKLIST.md; Codemagic is a
  phone-friendly option with a free tier for personal use (verify current terms).
- The APK from this workflow is signed with a **debug key** — fine for testing, **not for Google Play**.
  Play needs a signed App Bundle with your upload key (see GOOGLE_PLAY_RELEASE_CHECKLIST.md). Creating a keystore
  without a computer is possible in CI (a one-off workflow running `keytool`) — ask Claude to generate it when you get there.

## Updating an existing repo
**Always upload the COMPLETE project zip.** (An earlier "changed files only" zip depended on a previous update that your repo
did not have, which caused missing-file build errors.)
1. In GitHub (browser, "Desktop site" if the upload button is hidden): *Add file → Upload files* → choose `lunanest.zip`
   (keep that exact name, do not unzip). Commit.
2. The **Unpack project** workflow runs, overwrites files with the ones in the zip (`unzip -o`), then deletes the zip.
   Files that exist in your repo but not in the zip are left alone.
3. Actions → **Android build** → Run workflow. The first step of the build now runs `tool/verify_project.py`; if any
   file is missing it stops immediately and lists exactly what is missing.
4. Install the new APK from Releases.
