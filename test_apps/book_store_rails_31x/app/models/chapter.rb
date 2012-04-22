class Chapter < ActiveRecord::Base
  has_many :pages, :dependent => :destroy
  belongs_to :book
end
