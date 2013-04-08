require 'spec_helper'
describe DataActive::Entity do
  context 'context' do
    let(:book_entity) { DataActive::Entity.new('book') }
    it ('should have a class of Book') { book_entity.klass.name == 'Book' }
    it ('should have an association with chapters') { book_entity.has_association_with? 'chapter' }
    it ('should have an association with book_price') { book_entity.has_association_with? 'book_price' }
    it ('should have an attribute named id') { book_entity.has_attribute? 'id' }
    it ('should have an attribute named title') { book_entity.has_attribute? 'title' }
  end
end