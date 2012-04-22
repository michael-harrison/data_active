Feature: Synchronise database with XML
  As a Developer
  I need to synchronise the my database with an XML document
  So my database reflects the content that exists in the XML document

  Scenario: Synchronise when I have some matching records in the database
    Given I have a fresh set of books
    And I have the "features/support/fixtures/xml/books_changed.xml" file
    When I synchronise with "features/support/fixtures/xml/books_changed.xml"
    Then the books in the database will be identical to those in "features/support/fixtures/xml/books_changed.xml"
    And the book price will be identical to those in "features/support/fixtures/xml/books_changed.xml"
    And the chapters will be identical to those in "features/support/fixtures/xml/books_changed.xml"
    And the database will contain identical pages for the chapters as those in "features/support/fixtures/xml/books_changed.xml"

  Scenario: Synchronise when there are no records in the database
    Given I have no books
    And I have the "features/support/fixtures/xml/books_changed.xml" file
    When I synchronise with "features/support/fixtures/xml/books_changed.xml"
    Then the books in the database will be identical to those in "features/support/fixtures/xml/books_changed.xml"
    And the chapters will be identical to those in "features/support/fixtures/xml/books_changed.xml"
    And the database will contain identical pages for the chapters as those in "features/support/fixtures/xml/books_changed.xml"

  Scenario: A one to one association exists on the current ActiveRecord class