# App Store Connect checklist for Connect IAP

Do this in App Store Connect before you submit a build that charges for Connect. The app code already uses these product IDs.

## Agreement and banking

1. Sign the **Paid Applications Agreement** (Agreements, Tax, and Banking).
2. Complete **bank** and **tax** information. Products will stay "Missing Metadata" until this is done.

## In-app purchases

Create a subscription group named **Connect** with:

| Product ID | Type | Price (US) | Duration |
|---|---|---|---|
| `connect.monthly` | Auto-renewable subscription | $3.99 | 1 month |
| `connect.yearly` | Auto-renewable subscription | $24.99 | 1 year |

Create a non-consumable:

| Product ID | Type | Price (US) |
|---|---|---|
| `connect.lifetime` | Non-consumable | $29.99 |

Do **not** add an Apple introductory offer / free trial on monthly or yearly. The in-app trial starts on first successful adapter connection.

For each product, add a localization (display name + description), a review screenshot, and a review note.

Enable **Family Sharing** on the subscription group and on lifetime.

Turn on **Billing Grace Period** for the subscription group.

## App record

Set these URLs on the AntiCEL app:

- Privacy Policy: https://sameerkhichi.github.io/AntiCELDocs/privacy.html
- Terms of Use / EULA: https://sameerkhichi.github.io/AntiCELDocs/terms.html (or Apple Standard EULA plus this custom Terms URL)

Deploy the updated `docs/privacy.html` and `docs/terms.html` to GitHub Pages before review.

## App description disclosure (paste and adjust)

Connect is optional live OBD. Try it free for one month after AntiCEL first connects to a supported adapter. After that: Connect Monthly $3.99, Connect Yearly $24.99, or Connect Lifetime $29.99. Subscriptions auto-renew unless canceled at least 24 hours before the period ends. Payment is charged to your Apple ID. Manage or cancel in the app (garage top left, or Settings → Connect Access) or in iOS Settings → Apple ID → Subscriptions. Privacy Policy: https://sameerkhichi.github.io/AntiCELDocs/privacy.html Terms: https://sameerkhichi.github.io/AntiCELDocs/terms.html

## Review notes (paste)

Connect live OBD is gated behind a one-month in-app trial. The trial is not an App Store introductory offer. It starts only after a successful ELM327 handshake with a supported BLE adapter (or the debug mock in TestFlight debug builds). Scanning does not start the trial. After the month, the user must buy connect.monthly, connect.yearly, or connect.lifetime. Restore Purchases and Cancel / Manage Subscription are on Connect Access (garage top left and Settings). Privacy Policy and Terms of Use links are on that same screen.

## Local testing in Xcode

1. Open `AntiCEL/Configuration/AntiCEL.storekit`.
2. In the AntiCEL scheme: Run → Options → StoreKit Configuration → AntiCEL.storekit.
3. Sandbox renewals are accelerated. Use Connect Access → Debug → Reset Trial to re-test the free month.

## Optional

- Enable iCloud Key-Value Storage on the App ID if you want trial start dates to sync across devices more reliably. The app already writes to `NSUbiquitousKeyValueStore`; without the capability it simply will not sync.
- Keep the custom trial. Adding an Apple intro offer would start a second trial at subscribe time and require a card on file.
