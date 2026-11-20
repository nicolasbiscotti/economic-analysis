@id:fixed-expenses.expected-amount
Feature: Change the Expected Amount
  An Expected Amount change applies from a chosen Month until the next
  change. Each Payment shows the Expected Amount of its Month. Once an
  Expected Amount is set it can be changed, but never cleared.

  @id:fixed-expenses.expected-amount.from-a-month
  Scenario: A change applies from its Month onwards, not before
    Given a Fixed Expense "Rent" in ARS from January 2026 expecting 500000
    When I change the Expected Amount of "Rent" to 600000 from April 2026
    Then the Payments of "Rent" from March 2026 to May 2026 are:
      | Month      | Status  | Expected Amount |
      | March 2026 | Pending | 500000          |
      | April 2026 | Pending | 600000          |
      | May 2026   | Pending | 600000          |

  @id:fixed-expenses.expected-amount.until-next-change
  Scenario: A change runs until the next change, which is kept
    Given a Fixed Expense "Rent" in ARS from January 2026 expecting 500000
    And the Expected Amount of "Rent" changes to 600000 from June 2026
    When I change the Expected Amount of "Rent" to 550000 from March 2026
    Then the Payments of "Rent" from February 2026 to June 2026 are:
      | Month         | Status  | Expected Amount |
      | February 2026 | Pending | 500000          |
      | March 2026    | Pending | 550000          |
      | April 2026    | Pending | 550000          |
      | May 2026      | Pending | 550000          |
      | June 2026     | Pending | 600000          |

  @id:fixed-expenses.expected-amount.paid-payment-keeps-amount-paid
  Scenario: A Paid Payment shows the new Expected Amount and keeps its Amount Paid
    Given a Fixed Expense "Rent" in ARS from January 2026 expecting 500000
    And the March 2026 Payment of "Rent" is Paid with 480000
    When I change the Expected Amount of "Rent" to 550000 from March 2026
    Then the March 2026 Payment of "Rent" is Paid with 480000 expecting 550000

  @id:fixed-expenses.expected-amount.set-later
  Scenario: A blank Expected Amount can be set from a Month onwards
    Given a Fixed Expense "Electricity" in ARS from March 2026 with no Expected Amount
    When I change the Expected Amount of "Electricity" to 45000 from May 2026
    Then the Payments of "Electricity" from April 2026 to May 2026 are:
      | Month      | Status  | Expected Amount |
      | April 2026 | Pending |                 |
      | May 2026   | Pending | 45000           |

  @id:fixed-expenses.expected-amount.cannot-clear
  Scenario: An Expected Amount cannot be cleared
    Given a Fixed Expense "Electricity" in ARS from March 2026 expecting 45000
    When I clear the Expected Amount of "Electricity" from June 2026
    Then it is refused because an Expected Amount cannot be cleared
    And nothing has changed

  @id:fixed-expenses.expected-amount.not-positive
  Scenario: A change to an amount that is not positive is refused
    Given a Fixed Expense "Rent" in ARS from January 2026 expecting 500000
    When I change the Expected Amount of "Rent" to 0 from April 2026
    Then it is refused because the Expected Amount is not positive
    And nothing has changed

  @id:fixed-expenses.expected-amount.month-outside-range
  Scenario: A change from a Month outside the Fixed Expense's Months is refused
    Given a Fixed Expense "School" in ARS from March 2026 to December 2026 expecting 300000
    When I change the Expected Amount of "School" to 320000 from January 2027
    Then it is refused because the Month is outside the Fixed Expense's Months
    And nothing has changed
