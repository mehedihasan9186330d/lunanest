# Privacy Policy — TEMPLATE

> This is a starting point, not legal advice. Have it reviewed, fill every [PLACEHOLDER], host it at
> a public URL (required by both stores), and keep it in sync with the store privacy forms.

The same text ships inside the app at `assets/legal/privacy.txt`; keep the two identical.

See that file for the full text. Facts this template relies on (re-verify if you change the code):

- No accounts, no ads, no analytics, no crash-reporting SDK in this codebase.
- Favorites, recents, mixes, settings and downloads are stored locally.
- RevenueCat (`purchases_flutter`) is the only third-party SDK that sends data (anonymous app user ID,
  purchase/entitlement status, device/store metadata). Google Play Billing / StoreKit process payments.
- Remote audio (if you add any) is fetched over HTTPS from your host.
