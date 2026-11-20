# PayMongo test-mode payment state machine

The authoritative transition boundary is
`public.process_paymongo_payment_event`. Both verified webhooks and manual
provider reconciliation use this RPC; clients do not write payment outcomes.

| Current state | Verified event | Result |
|---|---|---|
| `checkout_created`, `processing`, or `failed` | Valid paid event with matching checkout/payment identity, amount, and PHP currency | Payment and booking become `paid` in one transaction; the ledger trigger records one credit |
| `paid` | Duplicate paid event | Ignored; no duplicate ledger entry |
| `paid` | Delayed failed or processing event | Ignored; success is not downgraded |
| `failed` | Later valid paid event | Upgraded to `paid`; provider truth may arrive after a failure event |
| Any non-refund state | Amount, currency, or established provider-payment identifier mismatch | Not paid; booking is placed `under_review` |
| `under_review` | Failed or processing event | Ignored until authoritative reconciliation or review resolves it |
| `refund_processing`, `partially_refunded`, or `refunded` | Paid, failed, or processing event | Ignored; the refund lifecycle is not reverted |
| No matching local payment/refund | Provider event | Transaction rolls back and returns a retryable processing failure; the event is not consumed |

Every provider event ID is inserted in the same transaction as its state
change. A committed duplicate returns `duplicate`; a database or transition
failure rolls the event insert back so provider retry remains possible.

Only test-mode PayMongo records are eligible. Live events and live credentials
remain rejected by the Edge Functions.

## Direct GCash booking payment

`gcash_direct` is a separate payment method for completed trips.
The booking is `unpaid` until the tourist reports sending the fare
(`gcash_awaiting_confirmation`) or the assigned driver confirms receipt
(`gcash_paid`). A driver can also report nonreceipt (`disputed`). An
unpaid or disputed direct GCash booking can switch to
`cash_awaiting_confirmation` and use the usual cash confirmations.
See [Direct GCash payment](gcash-direct-payment.md).
