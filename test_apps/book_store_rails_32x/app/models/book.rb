class Book < ActiveRecord::Base
  has_many :chapters, :dependent => :destroy
  has_one :book_price, :dependent => :destroy

  validates_presence_of :name
end
