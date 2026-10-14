# Troubleshooting first CI runs

| Symptom | Likely cause | Fix |
|---|---|---|
| `pub get` fails: version solving | Package ranges in pubspec.yaml incompatible with current Flutter | Paste the error to Claude; relax/bump the named package |
| Compile error in `lib/...` | Code was never compiled before | Paste the error lines to Claude |
| Gradle error about Java / AGP | Newer Flutter needs a newer JDK | In `ci/android.yml` change `java-version` to `"21"` |
| `purchasePackage` type error | purchases_flutter 9.x returns a different type | Keep `^8.0.0`, or ask Claude to port to 9.x |
| Manifest merger error for audio_service | Patch step not run | Check "Create android/ios folders" step log |
| App installs but no sound | Audio assets missing | Check "Generate original audio assets" step ran before `flutter build` |
| Notification doesn't show (Android 13+) | POST_NOTIFICATIONS runtime permission | Grant in system settings; add a runtime request flow |
| Paywall says "not configured" | No RevenueCat key was passed | Add secret `REVENUECAT_ANDROID_KEY`, re-run build |
| `Error: Not found: 'lib/ui/....dart'` / `CategoryStyle.accent` not defined | An older project + a partial update zip | Upload the complete `lunanest.zip` (see MOBILE_WORKFLOW.md). `tool/verify_project.py` reports exactly what is missing |
| `PROJECT VERIFICATION FAILED` in the build log | Files missing or inconsistent | Same as above; the message lists each problem |
