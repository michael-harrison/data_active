Feature: Synchronise one to one relationships
  As a Developer
  I need to synchronise one to one relationships in my database with an XML document
  So my database reflects the content that exists in the XML document

  Scenario: Create records when none exist in the database
    Given I have a fresh set of books without the one to one record
    And I have the "features/support/fixtures/xml/books_one_to_one_changed.xml" file
    When I synchronise with "features/support/fixtures/xml/books_one_to_one_changed.xml"
    Then the book price will be identical to those in "features/support/fixtures/xml/books_one_to_one_changed.xml"

  Scenario: Update existing records in the database
    Given I have a fresh set of books
    And I have the "features/support/fixtures/xml/books_one_to_one_changed.xml" file
    When I synchronise with "features/support/fixtures/xml/books_one_to_one_changed.xml"
    Then the book price will be identical to those in "features/support/fixtures/xml/books_one_to_one_changed.xml"

  Scenario: Replace records in the database
    Given I have a fresh set of books
    And I have the "features/support/fixtures/xml/books_one_to_one_mismatch.xml" file
    When I synchronise with "features/support/fixtures/xml/books_one_to_one_mismatch.xml"
    Then the book price will be identical to those in "features/support/fixtures/xml/books_one_to_one_mismatch.xml"

  Scenario: Remove records in the database
    Given I have a fresh set of books
    And I have the "features/support/fixtures/xml/books_one_to_one_removed.xml" file
    When I synchronise with "features/support/fixtures/xml/books_one_to_one_removed.xml"
    Then the book price will be identical to those in "features/support/fixtures/xml/books_one_to_one_removed.xml"

  Scenario: Duplicate records in the xml
    Given I have a fresh set of books
    And I have the "features/support/fixtures/xml/books_with_many_one_to_one_records.xml" file
    When I synchronise with "features/support/fixtures/xml/books_with_many_one_to_one_records.xml" I should get an error
