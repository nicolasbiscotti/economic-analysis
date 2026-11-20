@id:fixed-expenses.create
Feature: Create a Fixed Expense
  A Fixed Expense is owed every Month from its Start Month, and up to its
  End Month when it has one. Each of those Months has one Payment, which
  starts out Pending.

  @id:fixed-expenses.create.open-ended
  Scenario: A Fixed Expense with no End Month has a Pending Payment every Month from its Start Month
    When I create a Fixed Expense "Rent" in ARS from March 2026 expecting 500000
    Then the Payments of "Rent" from March 2026 to May 2026 are:
      | Month      | Status  | Expected Amount |
      | March 2026 | Pending | 500000          |
      | April 2026 | Pending | 500000          |
      | May 2026   | Pending | 500000          |
    And "Rent" has no Payment in February 2026

  @id:fixed-expenses.create.with-end-month
  Scenario: A Fixed Expense with an End Month has no Payments after it
    When I create a Fixed Expense "School" in ARS from March 2026 to December 2026 expecting 300000
    Then the December 2026 Payment of "School" is Pending expecting 300000
    And "School" has no Payment in January 2027

  @id:fixed-expenses.create.past-start-month
  Scenario: A Start Month in the past gives Pending Payments for the past Months
    When I create a Fixed Expense "Internet" in ARS from January 2020 expecting 15000
    Then the January 2020 Payment of "Internet" is Pending expecting 15000

  @id:fixed-expenses.create.no-expected-amount
  Scenario: The Expected Amount may be left blank
    When I create a Fixed Expense "Electricity" in ARS from March 2026 with no Expected Amount
    Then the March 2026 Payment of "Electricity" is Pending with no Expected Amount

  @id:fixed-expenses.create.duplicate-name
  Scenario: Two Fixed Expenses may share a name
    Given a Fixed Expense "Rent" in ARS from March 2026 expecting 500000
    When I create a Fixed Expense "Rent" in USD from March 2026 expecting 400
    Then there are 2 Fixed Expenses named "Rent"

  @id:fixed-expenses.create.blank-name
  Scenario: A blank name is refused
    When I create a Fixed Expense "   " in ARS from March 2026 expecting 500000
    Then it is refused because the name is blank
    And there are no Fixed Expenses

  @id:fixed-expenses.create.expected-amount-not-positive
  Scenario Outline: An Expected Amount that is not positive is refused
    When I create a Fixed Expense "Rent" in ARS from March 2026 expecting <amount>
    Then it is refused because the Expected Amount is not positive
    And there are no Fixed Expenses

    Examples:
      | amount |
      | 0      |
      | -1     |

  @id:fixed-expenses.create.end-before-start
  Scenario: An End Month before the Start Month is refused
    When I create a Fixed Expense "School" in ARS from March 2026 to February 2026 expecting 300000
    Then it is refused because the End Month is before the Start Month
    And there are no Fixed Expenses
