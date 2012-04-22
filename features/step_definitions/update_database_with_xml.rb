require "active_record/fixtures"
require_relative "step_helper"

Then /^the books with the same identifying features as those in "([^"]*)" will be updated$/ do |xml_document_file|
  books_in_database = Book.all
  xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)

  # Ensure that all books in the xml document have been updated
  book_elements = xml_document.xpath("//book")
  book_elements.each do |book_element|
    book_id = book_element.xpath("//book/id")[0].text
    book_name = book_element.xpath("//book/name")[0].text
    begin
      book = Book.find(book_id)
    rescue
    end

    if book != nil
      if book_name != book.name
        fail "Book name in database doesn't match book name in xml for book with id #{book_id}, XML: #{book_name}, Database: #{book.name}"
      end
    end
  end

  # Check the records that don't exist in the XML Document haven't been changed
  @original_books.each do |original_book|
    xml_book = xml_document.xpath("//book[id[text()='#{original_book.id}']]")
    if xml_book.count == 0
      book_in_database = Book.find(original_book.id)
      if book_in_database.name != original_book.name
        fail "Book name in database doesn't match the original book name for book with id #{original_book.id}, Original: #{original_book.name}, Database: #{book_in_database.name}"
      end
    end
  end

  # Ensure there are no extra books
  if books_in_database.count != @original_books.count
    fail "There number of books in the database (#{books_in_database.count}) doesn't match the original number of books (#{@original_books.count})"
  end
end

Then /^the chapters with the same identifying features as those in "([^"]*)" will be updated$/ do |xml_document_file|
  chapters_in_database = Chapter.all
  xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)

  # Ensure that all chapters in the xml document have been updated
  xml_document.xpath("//book").each do |book_element|
    book_id = book_element.xpath("id").text
    xml_document.xpath("//book[id[text()='#{book_id}']]/chapters/chapter").each do |chapter_element|
      chapter_id = chapter_element.xpath("id")[0].text
      chapter_title = chapter_element.xpath("title")[0].text
      chapter_introduction = chapter_element.xpath("introduction")[0].text
      begin
        chapter = Chapter.find(chapter_id)
      rescue
      end

      if chapter != nil
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

  # Check the records that don't exist in the XML Document haven't been changed
  @original_chapters.each do |original_chapter|
    xml_chapter = xml_document.xpath("//chapter[id[text()='#{original_chapter.id}']]")
    if xml_chapter.count == 0
      chapter_in_database = Chapter.find(original_chapter.id)
      if chapter_in_database.title != original_chapter.title
        fail "Chapter title in database doesn't match the original chapter title for chapter with id #{original_chapter.id}, Original: #{original_chapter.title}, Database: #{chapter_in_database.title}"
      end
      if chapter_in_database.introduction != original_chapter.introduction
        fail "Chapter introduction in database doesn't match the original chapter introduction for chapter with id #{original_chapter.id}, Original: #{original_chapter.introduction}, Database: #{chapter_in_database.introduction}"
      end
      if chapter_in_database.book_id != original_chapter.book_id
        fail "Chapter book_id in database doesn't match the original chapter book_id for chapter with id #{original_chapter.id}, Original: #{original_chapter.book_id}, Database: #{chapter_in_database.book_id}"
      end
    end
  end

  # Ensure there are no extra chapters
  if chapters_in_database.count != @original_chapters.count
    fail "The number of chapters in the database (#{chapters_in_database.count}) doesn't match the original number of chapters (#{@original_chapters.count})"
  end
end

Then /^the pages with the same identifying features as those in "([^"]*)" will be updated$/ do |xml_document_file|
  xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)

  # Ensure that all chapters in the xml document have been updated
  xml_document.xpath("//book").each do |book_element|
    book_id = book_element.xpath("id").text
    xml_document.xpath("//book[id[text()='#{book_id}']]/chapters/chapter").each do |chapter_element|
      chapter_id = chapter_element.xpath("id")[0].text
      begin
        pages = Page.where(:chapter_id => chapter_id)
      rescue
      end

      if pages.count > 0
        xml_document.xpath("//chapter[id[text()='#{chapter_id}']]/pages/page").each do |page_element|
          page_id = page_element.xpath("id")[0].text
          page_content = page_element.xpath("content")[0].text
          page_number = page_element.xpath("number")[0].text
          begin
            page = Page.find(page_id)
          rescue
          end

          if page != nil
            if page_content != page.content
              file "Page content in database doesn't match page content in xml for page with id #{page_id}, XML: #{page_content}, Database: #{page.content}"
            end

            if page_number != page.number.to_s
              fail "Page number in database doesn't match page number in xml for page with id #{page_id}, XML: #{page_number}, Database: #{page.number}"
            end
          end
        end
      end
    end
  end

  # Check the records that don't exist in the XML Document haven't been changed
  @original_pages.each do |original_page|
    xml_page = xml_document.xpath("//page[id[text()='#{original_page.id}']]")
    if xml_page.count == 0
      page_in_database = Page.find(original_page.id)
      if page_in_database.content != original_page.content
        fail "Page content in database doesn't match the original page content for page with id #{original_page.id}, Original: #{original_chapter.content}, Database: #{chapter_in_database.content}"
      end
      if page_in_database.number != original_page.number
        fail "Page number in database doesn't match the original page number for page with id #{original_page.id}, Original: #{original_page.number}, Database: #{page_in_database.number}"
      end
      if page_in_database.chapter_id != original_page.chapter_id
        fail "Page chapter_id in database doesn't match the original page chapter_id for page with id #{original_page.id}, Original: #{original_page.chapter_id}, Database: #{page_in_database.chapter_id}"
      end
    end
  end

  # Ensure there are no extra pages
  pages_in_database = Page.all
  if pages_in_database.count != @original_pages.count
    fail "There number of pages in the database (#{pages_in_database.count}) doesn't match the original number of pages (#{@original_pages.count})"
  end
end
Given /^I have no matching books$/ do
  StepHelper.load_fixtures File.join(Rails.root, 'features', 'support', 'fixtures', 'no_matching_records')
end

