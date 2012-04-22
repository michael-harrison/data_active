require_relative "step_helper"

When /^I synchronise with "([^"]*)" to only remove mismatching records$/ do |xml_document_file|
  Book.many_from_xml(File.open(Rails.root.join(xml_document_file)).read, [:destroy]) != nil
end

Then /^the books in the database that don't exist in "([^"]*)" will no longer exist in the database$/ do |xml_document_file|
  xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)
  books_in_database = Book.all

  books_in_database.each do |book|
    xml_book = xml_document.xpath("//book[id[text()='#{book.id}']]")
    if (xml_book.count == 0)
      fail "Found book (id=#{book.id} in database that doesn't exist in the XML and should have been destroyed"
    end
  end

end

Then /^the book_prices in the database that don't exist in "([^"]*)" will no longer exist in the database$/ do |xml_document_file|
  xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)
  book_prices_in_database = BookPrice.all

  book_prices_in_database.each do |book_price|
    xml_book_price = xml_document.xpath("//book_price[id[text()='#{book_price.id}']]")
    if (xml_book_price.count == 0)
      fail "Found book_price (id=#{book_price.id} in database that doesn't exist in the XML and should have been destroyed"
    end
  end

end

When /^the chapters in the database that don't exist in "([^"]*)" will no longer exist in the database$/ do |xml_document_file|
  xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)
  chapters_in_database = Chapter.all

  chapters_in_database.each do |chapter|
    xml_chapter = xml_document.xpath("//chapter[id[text()='#{chapter.id}']]")
    if (xml_chapter.count == 0)
      fail "Found chapter (id=#{chapter.id} in database that doesn't exist in the XML and should have been destroyed"
    end
  end

end

When /^the pages in the database that don't exist in "([^"]*)" will no longer exist in the database$/ do |xml_document_file|
  xml_document = Nokogiri::XML(File.open(Rails.root.join(xml_document_file)).read)
  pages_in_database = Page.all

  pages_in_database.each do |page|
    xml_page = xml_document.xpath("//page[id[text()='#{page.id}']]")
    if (xml_page.count == 0)
      fail "Found page (id=#{page.id} in database that doesn't exist in the XML and should have been destroyed"
    end
  end

end

Then /^will have no books$/ do
  books = Book.all
  if books.count > 0
    fail "Books exist in the database"
  end
end

When /^will have no chapters$/ do
  chapters = Chapter.all
  if chapters.count > 0
    fail "Chapters exist in the database"
  end
end

When /^will have no pages$/ do
  pages = Page.all
  if pages.count > 0
    fail "Pages exist in the database"
  end
end

When /^will have no book prices$/ do
  book_prices = BookPrice.all
  if book_prices.count > 0
    fail "Book Prices exist in the database"
  end
end