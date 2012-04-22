Feature: Remove records missing in XML
  As a Developer
  I need to update the my database with an XML document
  So that records in my database that do not share the same identify features as those in the XML are removed from my database

  Scenario: Attempt removing missing records when records exist in the database with some matching records in the XML Document
    Given I have a fresh set of books
    And I have the "features/support/fixtures/xml/books_changed.xml" file
    When I synchronise with "features/support/fixtures/xml/books_changed.xml" to only remove mismatching records
    Then the books in the database that don't exist in "features/support/fixtures/xml/books_changed.xml" will no longer exist in the database
    And the chapters in the database that don't exist in "features/support/fixtures/xml/books_changed.xml" will no longer exist in the database
    And the pages in the database that don't exist in "features/support/fixtures/xml/books_changed.xml" will no longer exist in the database

  Scenario: Attempt removing missing records when no records exist in the database
    Given I have no books
    And I have the "features/support/fixtures/xml/books_changed.xml" file
    When I synchronise with "features/support/fixtures/xml/books_changed.xml" to only remove mismatching records
    Then will have no books
    And will have no chapters
    And will have no pages
    And will have no book prices

  Scenario: Attempt removing missing records when records exist but there are no matching records in the database
    Given I have no matching books
    And I have the "features/support/fixtures/xml/books_changed.xml" file
    When I synchronise with "features/support/fixtures/xml/books_changed.xml" to only remove mismatching records
    Then will have no books
    And will have no chapters
    And will have no pages
    And will have no book prices
