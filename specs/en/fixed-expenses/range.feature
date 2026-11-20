@id:fixed-expenses.range
Feature: Start Month, End Month, cancelling and reopening
  Setting an End Month cancels a Fixed Expense and keeps its history.
  Moving the Start or End Month is refused while Paid Payments would fall
  outside the new range. Pending Payments outside it are removed silently;
  removing Skipped Payments needs confirmation. Reopening keeps one
  continuous range, and the Months in the gap are all Pending or all
  Skipped.

  # Start Month

  @id:fixed-expenses.range.start-earlier
  Scenario: Moving the Start Month earlier adds Pending Payments with the old Start Month's Expected Amount
    Given a Fixed Expense "Rent" in ARS from March 2026 expecting 500000
    When I move the Start Month of "Rent" to January 2026
    Then the Payments of "Rent" from January 2026 to March 2026 are:
      | Month         | Status  | Expected Amount |
      | January 2026  | Pending | 500000          |
      | February 2026 | Pending | 500000          |
      | March 2026    | Pending | 500000          |

  @id:fixed-expenses.range.start-later-drops-pending
  Scenario: Moving the Start Month later removes Pending Payments without a warning
    Given a Fixed Expense "Rent" in ARS from January 2026 expecting 500000
    When I move the Start Month of "Rent" to March 2026
    Then "Rent" has no Payment in February 2026
    And the March 2026 Payment of "Rent" is Pending expecting 500000

  @id:fixed-expenses.range.start-later-over-paid
  Scenario: Moving the Start Month past a Paid Payment is refused
    Given a Fixed Expense "Rent" in ARS from January 2026 expecting 500000
    And the February 2026 Payment of "Rent" is Paid with 500000
    When I move the Start Month of "Rent" to March 2026
    Then it is refused because Paid Payments would fall outside the range
    And nothing has changed

  @id:fixed-expenses.range.start-later-over-skipped
  Scenario: Moving the Start Month past a Skipped Payment warns first
    Given a Fixed Expense "Gym" in ARS from January 2026 expecting 20000
    And the February 2026 Payment of "Gym" is Skipped
    When I move the Start Month of "Gym" to March 2026
    Then I am warned that Skipped Payments will be removed
    When I confirm
    Then "Gym" has no Payment in February 2026

  @id:fixed-expenses.range.start-after-end
  Scenario: Moving the Start Month after the End Month is refused
    Given a Fixed Expense "School" in ARS from March 2026 to December 2026 expecting 300000
    When I move the Start Month of "School" to January 2027
    Then it is refused because the End Month is before the Start Month
    And nothing has changed

  # Cancelling (End Month)

  @id:fixed-expenses.range.cancel-keeps-history
  Scenario: Setting an End Month cancels the Fixed Expense and keeps its history
    Given a Fixed Expense "Gym" in ARS from January 2026 expecting 20000
    And the February 2026 Payment of "Gym" is Paid with 20000
    When I set the End Month of "Gym" to March 2026
    Then the Payments of "Gym" from January 2026 to March 2026 are:
      | Month         | Status  | Expected Amount | Amount Paid |
      | January 2026  | Pending | 20000           |             |
      | February 2026 | Paid    | 20000           | 20000       |
      | March 2026    | Pending | 20000           |             |
    And "Gym" has no Payment in April 2026

  @id:fixed-expenses.range.end-earlier-over-paid
  Scenario: Setting an End Month before a Paid Payment is refused
    Given a Fixed Expense "Gym" in ARS from January 2026 expecting 20000
    And the May 2026 Payment of "Gym" is Paid with 20000
    When I set the End Month of "Gym" to March 2026
    Then it is refused because Paid Payments would fall outside the range
    And nothing has changed

  @id:fixed-expenses.range.end-earlier-over-skipped
  Scenario: Setting an End Month before a Skipped Payment warns first
    Given a Fixed Expense "Gym" in ARS from January 2026 expecting 20000
    And the May 2026 Payment of "Gym" is Skipped
    When I set the End Month of "Gym" to March 2026
    Then I am warned that Skipped Payments will be removed
    When I confirm
    Then "Gym" has no Payment in May 2026

  @id:fixed-expenses.range.end-before-start
  Scenario: An End Month before the Start Month is refused
    Given a Fixed Expense "Gym" in ARS from March 2026 expecting 20000
    When I set the End Month of "Gym" to February 2026
    Then it is refused because the End Month is before the Start Month
    And nothing has changed

  # Reopening

  @id:fixed-expenses.range.reopen-gap-pending
  Scenario: Reopening fills the gap with Pending Payments when chosen
    Given a Fixed Expense "Gym" in ARS from January 2026 to March 2026 expecting 20000
    When I reopen "Gym" from July 2026 filling the gap as Pending
    Then the Payments of "Gym" from March 2026 to August 2026 are:
      | Month       | Status  | Expected Amount |
      | March 2026  | Pending | 20000           |
      | April 2026  | Pending | 20000           |
      | May 2026    | Pending | 20000           |
      | June 2026   | Pending | 20000           |
      | July 2026   | Pending | 20000           |
      | August 2026 | Pending | 20000           |

  @id:fixed-expenses.range.reopen-gap-skipped
  Scenario: Reopening fills the gap with Skipped Payments when chosen
    Given a Fixed Expense "Gym" in ARS from January 2026 to March 2026 expecting 20000
    When I reopen "Gym" from July 2026 filling the gap as Skipped
    Then the Payments of "Gym" from April 2026 to July 2026 are:
      | Month      | Status  | Expected Amount |
      | April 2026 | Skipped | 20000           |
      | May 2026   | Skipped | 20000           |
      | June 2026  | Skipped | 20000           |
      | July 2026  | Pending | 20000           |

  @id:fixed-expenses.range.reopen-no-gap
  Scenario: Reopening from the Month after the End Month extends it with no gap
    Given a Fixed Expense "Gym" in ARS from January 2026 to March 2026 expecting 20000
    When I reopen "Gym" from April 2026
    Then the April 2026 Payment of "Gym" is Pending expecting 20000
    And "Gym" has no End Month

  @id:fixed-expenses.range.reopen-with-new-end-month
  Scenario: Reopening may set a new End Month
    Given a Fixed Expense "Gym" in ARS from January 2026 to March 2026 expecting 20000
    When I reopen "Gym" from July 2026 to September 2026 filling the gap as Skipped
    Then the September 2026 Payment of "Gym" is Pending expecting 20000
    And "Gym" has no Payment in October 2026

  @id:fixed-expenses.range.reopen-gap-fill-required
  Scenario: Reopening with a gap needs a choice of how to fill it
    Given a Fixed Expense "Gym" in ARS from January 2026 to March 2026 expecting 20000
    When I reopen "Gym" from July 2026
    Then it is refused because the gap needs to be filled as Pending or Skipped
    And nothing has changed

  @id:fixed-expenses.range.reopen-not-ended
  Scenario: A Fixed Expense with no End Month cannot be reopened
    Given a Fixed Expense "Rent" in ARS from January 2026 expecting 500000
    When I reopen "Rent" from July 2026
    Then it is refused because the Fixed Expense has not ended
    And nothing has changed

  @id:fixed-expenses.range.reopen-within-range
  Scenario: Reopening from a Month that is not after the End Month is refused
    Given a Fixed Expense "Gym" in ARS from January 2026 to March 2026 expecting 20000
    When I reopen "Gym" from February 2026
    Then it is refused because the Month is not after the End Month
    And nothing has changed
