require 'factory_girl'

class BookGenerator
  def fresh
    FactoryGirl.create_list(:book, 2).each do |book|
      FactoryGirl.create(:book_price, book_id: book.id) if book.id.eql? 1
      FactoryGirl.create_list(:chapter, 3, book_id: book.id).each do |chapter|
        FactoryGirl.create_list(:page, )
      end
    end

  end

  def changed

  end

  def no_matching_records

  end

  def without_chapters

  end

  def without_one_to_one

  end
end