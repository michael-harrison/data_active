Feature: Synchronise one to many relationships
  As a Developer
  I need to synchronise one to many relationships in my database with an XML document
  So my database reflects the content that exists in the XML document

  Scenario: Create records when none exist in the database
    Given I have a fresh set of books without any chapters
    And I have the "features/support/fixtures/xml/books_with_chapters.xml" file
    When I synchronise with "features/support/fixtures/xml/books_with_chapters.xml"
    Then the chapters will be identical to those in "features/support/fixtures/xml/books_with_chapters.xml"

  Scenario: Update existing records in the database
    Given I have a fresh set of books
    And I have the "features/support/fixtures/xml/books_with_changed_chapters.xml" file
    When I synchronise with "features/support/fixtures/xml/books_with_changed_chapters.xml"
    Then the chapters will be identical to those in "features/support/fixtures/xml/books_with_changed_chapters.xml"

  Scenario: Parent changes records in the database
    Given I have a fresh set of books
    And I have the "features/support/fixtures/xml/books_with_moved_chapters.xml" file
    When I synchronise with "features/support/fixtures/xml/books_with_moved_chapters.xml"
    Then the chapters will be identical to those in "features/support/fixtures/xml/books_with_moved_chapters.xml"

  Scenario: Remove records in the database
    Given I have a fresh set of books
    And I have the "features/support/fixtures/xml/books_with_removed_chapters.xml" file
    When I synchronise with "features/support/fixtures/xml/books_one_to_one_removed.xml"
    Then the chapters will be identical to those in "features/support/fixtures/xml/books_one_to_one_removed.xml"

  Scenario: Providing an invalid set of records
    Given I have no books
    And I have the "features/support/fixtures/xml/books_changed_bad.xml" file
    When I synchronise with "features/support/fixtures/xml/books_changed_bad.xml" using the "fail_on_invalid" option
    Then I should have a failure

  Scenario Outline: Providing a set of record with no ids
    Given I have no books
    And I have the "<xml_file>" file
    When I synchronise with "<xml_file>"
    Then the books in the database will be identical to those in "<xml_file>" with new ids
    And the chapters will be identical to those in "<xml_file>" with new ids
    And the book price will be identical to those in "<xml_file>" with new ids

  Examples:
    | xml_file                                                            |
    | features/support/fixtures/xml/ms_access/books_fresh_without_ids.xml |
    | features/support/fixtures/xml/books_fresh_without_ids.xml           |
