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
The money a Fixed Expense is owed in, such as Argentine pesos or US dollars. It belongs to the Fixed Expense and never changes; its Expected Amount and every Amount Paid are in it, and amounts in different currencies are never added together or converted. The one exception is a Statement Balance, which may be settled in another currency.
_Spanish_: Moneda
_Avoid_: Denomination, home currency

**Payment Method**:
The Card a Payment was paid with, if any. Optional; a Payment paid with a Card becomes a Charge on that Card and is counted through its Statement, not on its own. A Fixed Expense may have a default Payment Method, pre-selected when one of its Payments is marked Paid.
_Spanish_: Medio de pago
_Avoid_: Payment type, account

**Variable Expense**:
A one-off amount spent outside a Card on a date, such as groceries paid in cash or by transfer. It is never Pending. A one-off amount spent on a Card is a Charge. Reserved for a future module and not part of v1.
_Spanish_: Gasto variable
_Avoid_: Purchase, transaction, spend

**Month**:
A calendar month (for example, March 2026), judged by the person's local date. Every Fixed Expense repeats once per Month; there are no other frequencies or custom pay cycles.
_Spanish_: Mes
_Avoid_: Period, cycle

## Credit cards

**Card**:
One credit card account, such as Visa Banco Galicia, with one Statement per Month. Additional cards for family members (*adicionales*) are part of the same Card.
_Spanish_: Tarjeta
_Avoid_: Credit card account, account

**Statement**:
What a Card is owed in one Month: the bill that closes in one month and is due in the Month it belongs to (the Month of its due date). It holds one Statement Balance per currency, and exists only when something is on it.
_Spanish_: Resumen
_Avoid_: Bill, invoice, card payment

**Closing Date**:
The date a Statement stops taking Charges. Each Statement starts from its Card's usual closing day and can be edited.
_Spanish_: Fecha de cierre
_Avoid_: Cut-off, period end

**Due Date**:
The date a Statement must be paid by; its Month is the Month of this date. Each Statement starts from its Card's usual due day and can be edited.
_Spanish_: Fecha de vencimiento
_Avoid_: Deadline, payment date

**Statement Balance**:
The total a Statement is owed in one currency, such as the ARS or the USD part of a Statement. It is the sum of the Charges and Installments on it in that currency, and it is settled by one Amount Paid, which may be lower than the total and may be in another currency (such as paying the USD part in pesos).
_Spanish_: Saldo
_Avoid_: Total, debt

**Charge**:
One amount spent on a Card on a date, in one currency. It lands on the first Statement whose Closing Date is on or after its date. A negative Charge is a credit, such as a refund.
_Spanish_: Consumo
_Avoid_: Purchase, transaction, movement

**Installment Purchase**:
A purchase on a Card paid in a number of equal Installments over consecutive Statements, starting with the Statement its date lands on. It can be ended early, removing the Installments not yet on a closed Statement.
_Spanish_: Compra en cuotas
_Avoid_: Financed purchase, plan

**Installment**:
One part of an Installment Purchase, landing on one Statement.
_Spanish_: Cuota
_Avoid_: Payment
