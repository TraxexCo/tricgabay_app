# Connected Android phone testing

The November 6, 2026 connected build uses the existing hosted Supabase project
`tric-gabay` (`xcsrjuqzwequmeqzedzd`). The service works over the phone's
internet connection; the PC does not need to stay running.

Build from the ignored, generated public client settings:

```powershell
flutter build apk --debug --flavor production --dart-define-from-file=config/phone-test.json --no-pub
```

The APK is `build/app/outputs/flutter-apk/app-production-debug.apk`. Its package
is `com.tricgabay.app`, matching the original Firebase Android registration.
It is debug-signed for direct installation and testing, not a store release.
The production flavor selects package identity; it does not enable real-money
payments. The database remains in PayMongo test mode with live payments disabled.

Three explicitly named synthetic accounts were created for phone testing:
`tricgabay.tourist.test@example.com`, `tricgabay.driver.test@example.com`,
and `tricgabay.admin.test@example.com`. Passwords are kept outside the repository
in the owner's local phone-testing artifact directory and were provided privately.
Do not use these accounts for real passenger service. The driver documents are
private JPEG fixtures clearly labeled TEST ONLY and are not valid documents.
The driver is approved for testing; the administrator has super-admin capability.

Verified on the hosted service:

- 53 migrations applied; 29 active catalog spots (rechecked November 8).
- Password sign-in, expected active role, catalog read, booking read and privacy
  notice retrieval for all three accounts.
- Driver compliance has no outstanding issues.
- A transaction-rolled-back cash booking workflow through dispatch, acceptance,
  pickup, stop confirmation, completion, cash confirmation and ledger recording.
- Mapbox Streets style request returned HTTP 200.
- Eight current Edge Functions deployed using the explicit import map.
- Authenticated health-check returned HTTP 200 and all five monitored metrics zero.

November 8 hosted hardening relocated PostGIS at the same version (3.3.7) into
the non-exposed `extensions` schema and fixed two application helper search
paths. Supabase was restarted and returned Healthy. All three synthetic logins,
catalog/consent reads and the rolled-back cash workflow passed afterward. The
public spatial table/RPC return HTTP 404; selecting the `extensions` API schema
returns HTTP 406/PGRST106. Existing APKs receive these server changes without
reinstallation. Leaked-password screening remains unavailable on the free plan.

The phone should show the current privacy notice for acceptance on first login.
To test a live tourist/driver exchange concurrently, use two phones or a second
signed-in client. Pickup remains restricted to the configured 15 km Bustos service
area. Real GPS, permissions, background tracking and push delivery still need
physical-device testing.

Password-reset HTTPS App Links still require the owner's real verified domain
and association file. No placeholder hostname was put into this APK. Test
PayMongo checkout/webhook/refund behavior remains to be exercised by the owner;
no actual charge or refund was initiated during setup. Local emergency numbers
remain administrator-editable placeholders until the owner fills verified numbers.

## Direct GCash payment

Use the updated client and a disposable or test backend with
the `20261120142544_gcash_direct_payment_*` and `20261120143304_gcash_receipts_disputes_rulings` migrations applied. Use separate tourist and
driver sessions. A real GCash transfer moves money independently of the
app. For a walkthrough, stop at GCash's send screen or use a mutually
agreed test transfer.

1. Add a GCash name and number as the driver. Try an invalid number and
   mismatched confirmation, then save a valid number and enable the option.
2. Book with **GCash (send to driver)** as the tourist, ensure a driver is
   requested before payment, and complete the trip.
3. Open trip payment and check the GCash name, number and exact saved fare.
4. Tap **Open GCash** on a device with GCash installed. Record whether GCash
   opens and whether the number or amount is prefilled (expected: no prefill).
   Repeat on a device without GCash and check the fallback message.
5. Check **Copy number** and **Copy amount** by pasting into a local note.
   The amount should contain two decimals and no symbol or grouping separator.
6. Tap **I've sent the payment** with and without a reference. Check the
   driver receives a push and sees the submitted reference in the booking.
7. Confirm receipt with the slider. Verify that both sessions update live
   and one direct GCash payment row exists.
8. Retry the same confirmation request twice. Verify that the same payment
   row remains the only direct GCash record for that booking.
9. In a separate booking, report **Not received yet**. Verify the tourist
   sees the dispute and can report again or switch to cash. Complete the
   fallback using both of the existing cash confirmations.
10. Repeat with GCash disabled or absent on the driver account. Check the
    cash fallback appears and there are no GCash launch or copy controls.
11. Run a standard cash booking and a PayMongo test checkout to verify both
    existing flows.
