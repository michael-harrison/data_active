Feature: Synchronise database with XML
  As a Developer
  I need to synchronise the my database with an XML document
  So my database reflects the content that exists in the XML document

  Scenario Outline: Synchronise when I have some matching records in the database
    Given I have a fresh set of books
    And I have the "<xml_file>" file
    When I synchronise with "<xml_file>"
    Then the books in the database will be identical to those in "<xml_file>"
    And the book price will be identical to those in "<xml_file>"
    And the chapters will be identical to those in "<xml_file>"
    And the database will contain identical pages for the chapters as those in "<xml_file>"
    
    Examples: 
      | xml_file                                                  |
      | features/support/fixtures/xml/ms_access/books_changed.xml           |
      | features/support/fixtures/xml/books_changed.xml |
    

  Scenario Outline: Synchronise when there are no records in the database
    Given I have no books
    And I have the "<xml_file>" file
    When I synchronise with "<xml_file>"
    Then the books in the database will be identical to those in "<xml_file>"
    And the chapters will be identical to those in "<xml_file>"
    And the database will contain identical pages for the chapters as those in "<xml_file>"

  Examples: 
    | xml_file                                                  |
    | features/support/fixtures/xml/books_changed.xml           |
    | features/support/fixtures/xml/ms_access/books_changed.xml |
