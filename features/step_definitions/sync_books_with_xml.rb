require "nokogiri"
require "data_active"
require_relative "step_helper"
require "active_record/fixtures"

Given /^I have no books$/ do
  Book.destroy_all
  books_in_database = Book.all
  if books_in_database.count > 0
    fail "Records still exist in the database"
  end
end

When /^I have the "([^"]*)" file$/ do |xml_document_file|
  if File.exists?(xml_document_file)
    xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)
    xml_document.children.first.name.downcase.eql?("books") || xml_document.children.first.name.downcase.eql?("book")
  else
    fail "XML File doesn't exist"
  end
end

When /^I synchronise with "([^"]*)"$/ do |xml_document_file|
  Book.many_from_xml(File.open(Rails.root.join(xml_document_file)), [:sync]) != nil
end

When /^I synchronise with "([^"]*)" I should get an error$/ do |xml_document_file|
  failed = true
  begin
    Book.many_from_xml(File.open(Rails.root.join(xml_document_file)).read, [:sync]) != nil
  rescue
    failed = false
  end

  fail "Error was didn't happen" if failed
end

When /^I update with "([^"]*)"$/ do |xml_document_file|
  @original_books = Book.all
  @original_chapters = Chapter.all
  @original_pages = Page.all
  Book.many_from_xml(File.open(Rails.root.join(xml_document_file)).read, [:update]) != nil
end

Then /^the books in the database will be identical to those in "([^"]*)"$/ do |xml_document_file|
  books_in_database = Book.all
  if books_in_database.count > 0
    books_xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)

    # Ensure that all books in the xml document have been recorded
    book_elements = books_xml_document.xpath("//book")
    book_elements.each do |book_element|
      book_id = book_element.xpath("//book/id")[0].text
      book_name = book_element.xpath("//book/name")[0].text
      book = Book.find(book_id)
      if book == nil
        fail "Books with id #{book_id} is missing"
      else
        if book_name != book.name
          fail "Book name in database doesn't match book name in xml for book with id #{book_id}, XML: #{book_name}, Database: #{book.name}"
        end
      end
    end

    # Ensure there are not extra books
    books_in_xml = books_xml_document.xpath("//book")
    if books_in_database.count != books_in_xml.count
      fail "There number of books in the database (#{books_in_database.count}) doesn't match the number of books in the xml document (#{books_in_xml.count})"
    end

  else
    fail "no books recorded"
  end
end

Then /^the books in the database will be identical to those in "([^"]*)" with new ids$/ do |xml_document_file|
  books_in_database = Book.all
  books_xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)

  # Ensure that all books in the xml document have been recorded
  book_elements = books_xml_document.xpath("//book")
  book_elements.each do |book_element|
    book_name = book_element.xpath("//book/name")[0].text
    book = Book.where(:name => book_name).first
    if book == nil
      fail "Books for #{book_name} is missing"
    end
  end

  # Ensure there are not extra books
  books_in_xml = books_xml_document.xpath("//book")
  if books_in_database.count != books_in_xml.count
    fail "There number of books in the database (#{books_in_database.count}) doesn't match the number of books in the xml document (#{books_in_xml.count})"
  end
end

When /^the book price will be identical to those in "([^"]*)"$/ do |xml_document_file|
  book_prices_in_database = BookPrice.all
  if book_prices_in_database.count > 0
    xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)

    # Ensure that all chapters in the xml document have been recorded

    xml_document.xpath("//book").each do |book_element|
      book_id = book_element.xpath("id").text

      xml_document.xpath("//book[id[text()='#{book_id}']]/book_price").each do |book_price_element|
        book_price_id = book_price_element.xpath("id")[0].text
        book_price = BookPrice.find book_price_id
        if book_price.nil?
          fail "BookPrice with id #{book_price_id} is missing"
        else
          if book_price.book_id.nil?
            fail "BookPrice.book_id in database isn't being set (expecting book_id = #{book_id})"
          elsif book_price.book_id != book_id.to_i
            fail "BookPrice.book_id in database is set incorrectly (expecting book_id = #{book_id} and got #{book_price.book_id})"
          end

          book_price_sell = book_price_element.xpath("sell").text
          book_price_educational = book_price_element.xpath("educational").text
          book_price_cost = book_price_element.xpath("cost").text

          if Float(book_price_sell) != book_price.sell
            fail "BookPrice 'sell' in database doesn't match book price sell in xml for book price with id #{book_price_id}, XML: #{book_price_sell}, Database: #{book_price.sell}"
          end

          if Float(book_price_cost) != book_price.cost
            fail "BookPrice 'cost' in database doesn't match book price cost in xml for book price with id #{book_price_id}, XML: #{book_price_cost}, Database: #{book_price.cost}"
          end

          if Float(book_price_educational) != book_price.educational
            fail "BookPrice 'educational' in database doesn't match book price educational in xml for book price with id #{book_price_id}, XML: #{book_price_educational}, Database: #{book_price.educational}"
          end

          if Integer(book_id) != book_price.book_id
            fail "BookPrice 'book_id' in database doesn't match book_id in xml for book price with id #{book_price_id}, XML: #{book_id}, Database: #{book_price.book_id}"
          end
        end
      end
    end

    # Ensure there are not extra book prices
    book_prices_in_xml = xml_document.xpath("//book_price")
    if book_prices_in_database.count != book_prices_in_xml.count
      fail "There number of book prices in the database (#{book_prices_in_database.count}) doesn't match the number of book prices in the xml document (#{book_prices_in_xml.count})"
    end
  end
end

When /^the book price will be identical to those in "([^"]*)" with new ids$/ do |xml_document_file|
  xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)

  # Ensure that all chapters in the xml document have been recorded
  xml_document.xpath('//book').each do |book_element|
    book = Book.find_by_name book_element.xpath('name')[0].text
    book_id = book.id
    book_price_element = book_element.xpath('book_price')
    book_price = BookPrice.find_by_book_id book_id

    fail 'Too many book prices' if book_price_element.count > 1

    if book_price.nil?
      fail "BookPrice for book '#{book.name}' is missing"
    else
      book_price_sell = book_price_element.xpath('sell').text
      book_price_educational = book_price_element.xpath('educational').text
      book_price_cost = book_price_element.xpath('cost').text

      if Float(book_price_sell) != book_price.sell
        fail "BookPrice 'sell' in database doesn't match book price sell in xml for book '#{book.name}', XML: #{book_price_sell}, Database: #{book_price.sell}"
      end

      if Float(book_price_cost) != book_price.cost
        fail "BookPrice 'cost' in database doesn't match book price cost in xml for book '#{book.name}', XML: #{book_price_cost}, Database: #{book_price.cost}"
      end

      if Float(book_price_educational) != book_price.educational
        fail "BookPrice 'educational' in database doesn't match book price educational in xml for book '#{book.name}', XML: #{book_price_educational}, Database: #{book_price.educational}"
      end
    end
  end
end

When /^the chapters will be identical to those in "([^"]*)"$/ do |xml_document_file|
  chapters_in_database = Chapter.all
  if chapters_in_database.count > 0
    xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)

    # Ensure that all chapters in the xml document have been recorded
    xml_document.xpath("//book").each do |book_element|
      book_id = book_element.xpath("id").text
      xml_document.xpath("//book[id[text()='#{book_id}']]/chapters/chapter").each do |chapter_element|
        chapter_id = chapter_element.xpath("id")[0].text
        chapter_title = chapter_element.xpath("title")[0].text
        chapter_introduction = chapter_element.xpath("introduction")[0].text
        chapter = Chapter.find(chapter_id)

        if chapter == nil
          fail "Chapters with id #{chapter_id} is missing"
        else
          if chapter_title != chapter.title
            fail "Chapter title in database doesn't match chapter title in xml for chapter with id #{chapter_id}, XML: #{chapter_title}, Database: #{chapter.title}"
          end
          if chapter_introduction != chapter.introduction
            fail "Chapter introduction in database doesn't match chapter introduction in xml for chapter with id #{chapter_id}, XML: #{chapter_introduction}, Database: #{chapter.introduction}"
          end
          if book_id != chapter.book_id.to_s
            fail "Chapter book_id in database doesn't match chapter book_id in xml for chapter with id #{chapter_id}, XML: #{book_id}, Database: #{chapter.book_id}"
          end
        end
      end
    end


    # Ensure there are not extra chapters
    chapters_in_xml = xml_document.xpath("//chapter")
    if chapters_in_database.count != chapters_in_xml.count
      fail "There number of chapters in the database (#{chapters_in_database.count}) doesn't match the number of chapters in the xml document (#{chapters_in_xml.count})"
    end

  else
    fail "no chapters recorded"
  end
end

When /^the chapters will be identical to those in "([^"]*)" with new ids$/ do |xml_document_file|
  xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)

  # Ensure that all chapters in the xml document have been recorded
  xml_document.xpath("//book").each do |book_element|
    book = Book.where(:name => book_element.xpath("name")[0].text).first
    book_id = book.id
    xml_document.xpath("//book[name[text()='#{book.name}']]/chapters/chapter").each do |chapter_element|
      chapter_title = chapter_element.xpath("title")[0].text
      chapter_introduction = chapter_element.xpath("introduction")[0].text
      chapter = book.chapters.where(:title => chapter_title).first

      if chapter == nil
        fail "Chapters #{chapter_title} is missing"
      else
        if chapter.book_id.nil?
          fail "Chapter.book_id in database isn't being set (expecting book_id = #{book_id}"
        elsif chapter.book_id != book_id
          fail "Chapter.book_id in database is set incorrectly (expecting book_id = #{book_id} and got #{chapter.book_id})"
        end
        if chapter_introduction != chapter.introduction
          fail "Chapter introduction in database doesn't match chapter introduction in xml for chapter #{chapter_title}, XML: #{chapter_introduction}, Database: #{chapter.introduction}"
        end
        if book_id != chapter.book_id
          fail "Chapter book_id in database doesn't match chapter book_id in xml for chapter #{chapter_title}, XML: #{book_id}, Database: #{chapter.book_id}"
        end
      end
    end
  end


  # Ensure there are not extra chapters
  chapters_in_xml = xml_document.xpath("//chapter")
  chapter_count = Chapter.count
  if chapter_count != chapters_in_xml.count
    fail "There number of chapters in the database (#{chapter_count}) doesn't match the number of chapters in the xml document (#{chapters_in_xml.count})"
  end
end

When /^the database will contain identical pages for the chapters as those in "([^"]*)"$/ do |xml_document_file|
  chapters_in_database = Chapter.all
  if chapters_in_database.count > 0
    xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)

    # Ensure that all chapters in the xml document have been recorded
    xml_document.xpath("//book").each do |book_element|
      book_id = book_element.xpath("id").text
      xml_document.xpath("//book[id[text()='#{book_id}']]/chapters/chapter").each do |chapter_element|
        chapter_id = chapter_element.xpath("id")[0].text
        pages = Page.where(:chapter_id => chapter_id)
        if pages.count > 0
          xml_document.xpath("//chapter[id[text()='#{chapter_id}']]/pages/page").each do |page_element|
            page_id = page_element.xpath("id")[0].text
            page_content = page_element.xpath("content")[0].text
            page_number = page_element.xpath("number")[0].text
            page = Page.find(page_id)

            if page == nil
              fail "Page with id #{page_id} is missing"
            else
              if page_content != page.content
                fail "Page content in database doesn't match page content in xml for page with id #{page_id}, XML: #{page_content}, Database: #{page.content}"
              end
              
              if page_number != page.number.to_s
                fail "Page number in database doesn't match page number in xml for page with id #{page_id}, XML: #{page_number}, Database: #{page.number}"
              end
            end
          end
        else
          fail "no pages recorded for chapter with id #{chapter_id}"
        end
      end
    end


    # Ensure there are not extra pages
    pages_in_xml = xml_document.xpath("//page")
    pages_in_database = Page.all
    if pages_in_database.count != pages_in_xml.count
      fail "There number of pages in the database (#{pages_in_database.count}) doesn't match the number of pages in the xml document (#{pages_in_xml.count})"
    end

  else
    fail "no chapters recorded"
  end
end

Given /^I have a fresh set of books$/ do
  StepHelper.load_fixtures File.join(Rails.root, 'features', 'support', 'fixtures', 'fresh')
end

Given /^I have a fresh set of books without the one to one record$/ do
  StepHelper.load_fixtures File.join(Rails.root, 'features', 'support', 'fixtures', 'without_one_to_one')
end

Given /^I have a fresh set of books without any chapters$/ do
  StepHelper.load_fixtures File.join(Rails.root, 'features', 'support', 'fixtures', 'without_chapters')
end

When /^I synchronise with "([^"]*)" using the "([^"]*)" (?:option|options)$/ do |xml_document_file, sync_options|
  @error_message = nil
  begin
    options = sync_options.split(',').map {|option| option.strip.to_sym }
    puts options
    Book.many_from_xml(File.open(Rails.root.join(xml_document_file)).read, [:sync] + options) != nil
  rescue Exception => ex
    @error_message = ex.message
  end
end

Then /^I should have a failure$/ do
  fail "no error message" if @error_message.nil?
end
