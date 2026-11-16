# Expense Tracking

Personal tracking of the expenses a person pays every month, across all their devices.

Each term is named in the most natural English first. Its Spanish name is the most natural Argentine Spanish (es-AR) word for the same concept, not a literal translation. Other regional variants of Spanish may name terms differently in the app; they never change the English term.

## Language

**Fixed Expense**:
An expense the person pays every month, such as rent, school or internet. "Fixed" means it repeats every month, not that its amount stays the same.
_Spanish_: Gasto fijo
_Avoid_: Recurring expense, bill, subscription

**Expected Amount**:
The amount a Fixed Expense is expected to cost in a month. Optional, because some expenses (such as electricity) have no predictable amount.
_Spanish_: Monto esperado
_Avoid_: Budget, price, estimate

**Start Month**:
The first calendar month in which a Fixed Expense is owed.
_Spanish_: Mes de inicio

**End Month**:
The last calendar month in which a Fixed Expense is owed, inclusive. Optional; setting it is how a Fixed Expense is cancelled while keeping its history.
_Spanish_: Mes de fin
_Avoid_: Cancellation date, expiry

**Payment**:
What a Fixed Expense is owed in one Month, such as the March 2026 rent. It always has exactly one Payment Status.
_Spanish_: Pago
_Avoid_: Occurrence, instance, installment, bill, charge

**Payment Status**:
The state of a Payment: **Pending** (owed, not yet paid), **Paid** (settled, with an Amount Paid) or **Skipped** (not owed this Month, such as a frozen gym membership).
_Spanish_: Estado del pago: Pendiente, Pagado, No corresponde
_Avoid_: Unpaid, open, closed, cancelled

**Amount Paid**:
The amount actually paid to settle a Payment, which may differ from its Expected Amount.
_Spanish_: Monto pagado
_Avoid_: Actual amount, cost

**Currency**:
The money a Fixed Expense is owed in, such as Argentine pesos or US dollars. It belongs to the Fixed Expense and never changes; its Expected Amount and every Amount Paid are in it, and amounts in different currencies are never added together or converted.
_Spanish_: Moneda
_Avoid_: Denomination, home currency

**Variable Expense**:
A one-off amount spent on a date, such as groceries, clothing or a birthday party. It is never Pending. Reserved for a future module and not part of v1.
_Spanish_: Gasto variable
_Avoid_: Purchase, transaction, spend

**Month**:
A calendar month (for example, March 2026), judged by the person's local date. Every Fixed Expense repeats once per Month; there are no other frequencies or custom pay cycles.
_Spanish_: Mes
_Avoid_: Period, cycle
