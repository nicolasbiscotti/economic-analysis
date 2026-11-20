@id:fixed-expenses.payments
Feature: Payments and their Payment Status
  Each Payment is Pending, Paid (with an Amount Paid and an optional paid
  date) or Skipped. Any Month can be edited, in the past or the future.
  A Payment can move between any two statuses, but moving away from Paid
  removes its Amount Paid, so the person is warned and must confirm.

  Background:
    Given a Fixed Expense "Rent" in ARS from January 2026 expecting 500000

  @id:fixed-expenses.payments.mark-paid
  Scenario: Marking a Payment Paid records the Amount Paid
    When I mark the April 2026 Payment of "Rent" as Paid with 500000
    Then the April 2026 Payment of "Rent" is Paid with 500000 expecting 500000

  @id:fixed-expenses.payments.mark-paid-different-amount
  Scenario: The Amount Paid may differ from the Expected Amount
    When I mark the April 2026 Payment of "Rent" as Paid with 480000
    Then the April 2026 Payment of "Rent" is Paid with 480000 expecting 500000

  @id:fixed-expenses.payments.mark-paid-with-date
  Scenario: A paid date may be recorded, even before the Payment's Month
    When I mark the April 2026 Payment of "Rent" as Paid with 500000 on 2026-03-28
    Then the April 2026 Payment of "Rent" was paid on 2026-03-28

  @id:fixed-expenses.payments.mark-paid-future-month
  Scenario: A future Month can be paid in advance
    When I mark the December 2030 Payment of "Rent" as Paid with 500000
    Then the December 2030 Payment of "Rent" is Paid with 500000 expecting 500000

  @id:fixed-expenses.payments.mark-paid-no-expected-amount
  Scenario: A Payment with no Expected Amount can be Paid
    Given a Fixed Expense "Electricity" in ARS from March 2026 with no Expected Amount
    When I mark the March 2026 Payment of "Electricity" as Paid with 41000
    Then the March 2026 Payment of "Electricity" is Paid with 41000 and no Expected Amount

  @id:fixed-expenses.payments.amount-paid-not-positive
  Scenario Outline: An Amount Paid that is not positive is refused
    When I mark the April 2026 Payment of "Rent" as Paid with <amount>
    Then it is refused because the Amount Paid is not positive
    And nothing has changed

    Examples:
      | amount |
      | 0      |
      | -1     |

  @id:fixed-expenses.payments.change-amount-paid
  Scenario: The Amount Paid of a Paid Payment can be corrected without a warning
    Given the April 2026 Payment of "Rent" is Paid with 480000
    When I change the Amount Paid of the April 2026 Payment of "Rent" to 490000
    Then the April 2026 Payment of "Rent" is Paid with 490000 expecting 500000

  @id:fixed-expenses.payments.skip
  Scenario: A Pending Payment can be Skipped
    When I mark the April 2026 Payment of "Rent" as Skipped
    Then the April 2026 Payment of "Rent" is Skipped

  @id:fixed-expenses.payments.skipped-to-pending
  Scenario: A Skipped Payment can go back to Pending
    Given the April 2026 Payment of "Rent" is Skipped
    When I mark the April 2026 Payment of "Rent" as Pending
    Then the April 2026 Payment of "Rent" is Pending expecting 500000

  @id:fixed-expenses.payments.skipped-to-paid
  Scenario: A Skipped Payment can be Paid
    Given the April 2026 Payment of "Rent" is Skipped
    When I mark the April 2026 Payment of "Rent" as Paid with 500000
    Then the April 2026 Payment of "Rent" is Paid with 500000 expecting 500000

  @id:fixed-expenses.payments.paid-to-pending-confirmed
  Scenario: Moving a Paid Payment back to Pending warns first and removes its Amount Paid once confirmed
    Given the April 2026 Payment of "Rent" is Paid with 480000 on 2026-04-05
    When I mark the April 2026 Payment of "Rent" as Pending
    Then I am warned that its Amount Paid will be removed
    When I confirm
    Then the April 2026 Payment of "Rent" is Pending expecting 500000
    And the April 2026 Payment of "Rent" has no paid date

  @id:fixed-expenses.payments.paid-to-pending-declined
  Scenario: Declining the warning leaves the Paid Payment as it was
    Given the April 2026 Payment of "Rent" is Paid with 480000
    When I mark the April 2026 Payment of "Rent" as Pending
    Then I am warned that its Amount Paid will be removed
    When I decline
    Then nothing has changed

  @id:fixed-expenses.payments.paid-to-skipped
  Scenario: Skipping a Paid Payment warns first and removes its Amount Paid once confirmed
    Given the April 2026 Payment of "Rent" is Paid with 480000
    When I mark the April 2026 Payment of "Rent" as Skipped
    Then I am warned that its Amount Paid will be removed
    When I confirm
    Then the April 2026 Payment of "Rent" is Skipped

  @id:fixed-expenses.payments.outside-range
  Scenario: A Month outside the Fixed Expense's Months has no Payment to mark
    When I mark the December 2025 Payment of "Rent" as Paid with 500000
    Then it is refused because the Month is outside the Fixed Expense's Months
    And nothing has changed
