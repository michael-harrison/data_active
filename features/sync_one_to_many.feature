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

  Scenario: Replace records in the database
    Given I have a fresh set of books
    And I have the "features/support/fixtures/xml/books_with_mismatched_chapters.xml" file
    When I synchronise with "features/support/fixtures/xml/books_with_mismatched_chapters.xml"
    Then the chapters will be identical to those in "features/support/fixtures/xml/books_with_mismatched_chapters.xml"

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
