# A Statement Balance may be settled in another currency

v1 never converts between currencies: every amount stays in its own Currency and Month totals are shown per currency. Statement Balances are the one exception. In Argentina the USD part of a card's Statement is commonly paid in pesos, and the pesos are what actually leave the person's account. So a Statement Balance's Amount Paid records the currency it was actually paid in (for example, US$ 100 owed, settled with $ 120.000), while Fixed Expense Payments stay single-currency. No exchange rate is stored or derived. In the Month totals, Expected counts the balance in its own currency and Paid counts it in the currency it was paid in.

## Considered Options

- **Settle each balance in its own currency only**: keeps the rule pure, but records US$ 100 paid when the person really spent $ 120.000, so the peso outflow is lost.
- **Introduce exchange rates**: would let totals be combined, but brings in rate sources and rate freezing, which v1 deliberately avoids.

## Consequences

- Stored Amount Paid values are in mixed currencies relative to their balances, and that can't be undone without data loss. Any future conversion or analytics module has to treat the paid currency as the source of truth for money that left the account.
