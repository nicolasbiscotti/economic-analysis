@id:fixed-expenses.rename-and-delete
Feature: Rename and delete a Fixed Expense
  Renaming applies to the whole history. Deleting is for mistakes: it erases
  the Fixed Expense and all its Payments, after a warning. To stop paying
  something while keeping its history, set an End Month instead.

  Background:
    Given a Fixed Expense "Rent" in ARS from January 2026 expecting 500000
    And the February 2026 Payment of "Rent" is Paid with 500000

  @id:fixed-expenses.rename-and-delete.rename
  Scenario: Renaming applies to every Payment, past and future
    When I rename "Rent" to "Apartment rent"
    Then the February 2026 Payment of "Apartment rent" is Paid with 500000 expecting 500000
    And the March 2026 Payment of "Apartment rent" is Pending expecting 500000
    And there is no Fixed Expense "Rent"

  @id:fixed-expenses.rename-and-delete.rename-blank
  Scenario: Renaming to a blank name is refused
    When I rename "Rent" to "   "
    Then it is refused because the name is blank
    And nothing has changed

  @id:fixed-expenses.rename-and-delete.delete-confirmed
  Scenario: Deleting warns first and erases the Fixed Expense and its history once confirmed
    When I delete "Rent"
    Then I am warned that its whole history will be erased
    When I confirm
    Then there is no Fixed Expense "Rent"

  @id:fixed-expenses.rename-and-delete.delete-declined
  Scenario: Declining the warning keeps the Fixed Expense
    When I delete "Rent"
    Then I am warned that its whole history will be erased
    When I decline
    Then nothing has changed
