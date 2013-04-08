require 'spec_helper'

describe DataActive::Parser do
  context 'parsing start' do
    let (:parser) { DataActive::Parser.new('book') }
    it ('should occur when the right element name is provided') { parser.begin('book'); parser.has_started_parsing? }
    it ('should not occur when the wrong element is provided') { parser.begin('dataroot'); parser.has_started_parsing? == false }
  end

  context 'when parsing attributes' do
    let (:parser) { DataActive::Parser.new('book') }
    it ('will get upset about mismatched tags') do
      parser.begin('book')

      parser.begin('id')
      parser.content('1')
      failed = true
      begin
        parser.end('name')
      rescue
        failed = false
      end

      fail('Allowed mismatched tags') if failed

    end

    it ('should record known attributes against the entity') do
      parser
      .begin('book')
        .begin('id').content('1').end('id')
        .begin('name').content('101 Testing').end('name')
        .begin('full_name').content('101 Testing: Your start to testing').end('full_name') # Unknown attribute

      entity = parser.stack.last
      entity.attributes['id'].name.should eq 'id'
      entity.attributes['id'].content.should eq '1'
      entity.attributes['name'].name.should eq 'name'
      entity.attributes['name'].content.should eq '101 Testing'
      attributes = entity.attributes.select { |key, a| a.name == 'full_name' }
      attributes.count.should eq 0
    end

    it ('should create records when the :create option is in use') do
      parser.options << :create

      parser
      .begin('book')
        .begin('id').content('2').end('id')
        .begin('name').content('101 Testing').end('name')
      .end('book')

      books = Book.all
      books.count.should eq 1
      books[0].id.should eq 1
      books[0].name.should eq '101 Testing'
    end

    it ('will update records when the :update option is in use') do
      book = Book.create! name: '101 Testing'

      parser.options << :update

      parser
      .begin('book')
        .begin('id').content(book.id).end('id')
        .begin('name').content('101 Testing again').end('name')
      .end('book')

      books = Book.all
      books.count.should eq 1
      books[0].id.should eq 1
      books[0].name.should eq '101 Testing again'
    end

    it ('should raise an error when strict mode is used') do
      parser.options << :strict
      parser.begin('book')
      failed = true
      begin
        parser.begin('bogus').content('1').end('bogus')
      rescue
        failed = false
      end
      fail('Element that was not either an attribute or association was allowed') if failed
    end

    it ('should all unknown element when not in strict mode') do
      parser
      .begin('book')
        .begin('bogus').content('1').end('bogus')
    end
  end

  context 'when parsing associations' do
    let (:parser) { DataActive::Parser.new('book') }

    it ('will get upset about mismatched tags') do
      parser
      .begin('book')
        .begin('id').content('1').end('id')

      failed = true
      begin
        parser.end('chapter')
      rescue
        failed = false
      end

      fail('Allowed mismatched tags') if failed

    end

    it ('should parse all associations known and unknown') do
      parser.options << :create
      parser
      .begin('book')
        .begin('id').content('1').end('id')
        .begin('name').content('Past, now and future').end('name')
        .begin('chapter')
          .begin('id').content('2').end('id')
          .begin('title').content('20/20 hindsight').end('title')
        .end('chapter')
        .begin('appendix')
          .begin('id').content('3').end('id')
          .begin('name').content('Appendix A - Swimming Rules').end('name')
          .begin('body').content('some swimming rules').end('body')
        .end('appendix')
        .begin('chapter')
          .begin('id').content('3').end('id')
          .begin('title').content('The future').end('title')
        .end('chapter')
      .end('book')
    end

    it ('should update :has_many associations with existing parent') do
      parser.options << :create
      parser.options << :update

      parser
      .begin('book')
        .begin('name').content('101 Testing again').end('name')
      .end('book')

      books = Book.all

      parser
      .begin('book')
        .begin('id').content(books[0].id).end('id')
        .begin('name').content('Past, now and future').end('name')
        .begin('chapter')
          .begin('id').content('2').end('id')
          .begin('title').content('20/20 hindsight').end('title')
        .end('chapter')
        .begin('chapter')
          .begin('id').content('3').end('id')
          .begin('title').content('The future').end('title')
        .end('chapter')
      .end('book')

      books = Book.all
      books.count.should eq 1
      chapters = Chapter.all
      chapters.count.should eq 2
      chapters[0].book_id.should eq books[0].id
      chapters[1].book_id.should eq books[0].id
    end

    it ('should update :has_many associations') do
      parser.options << :create

      parser
      .begin('book')
        .begin('id').content('1').end('id')
        .begin('name').content('Past, now and future').end('name')
        .begin('chapter')
          .begin('id').content('2').end('id')
          .begin('title').content('20/20 hindsight').end('title')
        .end('chapter')
        .begin('chapter')
          .begin('id').content('3').end('id')
          .begin('title').content('The future').end('title')
        .end('chapter')
      .end('book')

      books = Book.all
      books.count.should eq 1
      chapters = Chapter.all
      chapters.count.should eq 2
      chapters[0].book_id.should eq books[0].id
      chapters[1].book_id.should eq books[0].id
    end

    it ('should update :has_one associations with existing parent') do
      parser.options << :create
      parser.options << :update

      parser
      .begin('book')
        .begin('name').content('101 Testing again').end('name')
      .end('book')

      books = Book.all

      parser
      .begin('book')
        .begin('id').content(books[0].id).end('id')
        .begin('name').content('Past, now and future').end('name')
        .begin('book_price')
          .begin('id').content('2').end('id')
          .begin('educational').content('10.0').end('educational')
        .end('book_price')
      .end('book')

      books = Book.all
      books.count.should eq 1
      book_prices = BookPrice.all
      book_prices.count.should eq 1
      book_prices[0].book_id.should eq books[0].id
    end

    it ('should update :has_one associations') do
      parser.options << :create
      parser
      .begin('book')
        .begin('id').content('1').end('id')
        .begin('name').content('Past, now and future').end('name')
        .begin('book_price')
          .begin('id').content('2').end('id')
          .begin('educational').content('10.0').end('educational')
        .end('book_price')
      .end('book')

      books = Book.all
      books.count.should eq 1
      book_prices = BookPrice.all
      book_prices.count.should eq 1
      book_prices[0].book_id.should eq books[0].id
    end

    it ('should parse only known associations when in strict mode') do
      parser.options << :strict

      parser
      .begin('book')
        .begin('id').content('1').end('id')
        .begin('chapter')
          .begin('id').content('2').end('id')
          .begin('title').content('20/20 hindsight').end('title')
        .end('chapter')

      failed = true
      begin
        parser
        .begin('appendix')
          .begin('id').content('3').end('id')
          .begin('name').content('Appendix A - Swimming Rules').end('name')
          .begin('body').content('some swimming rules').end('body')
      rescue
        failed = false
      end
      fail('Element that was not either an attribute or association was allowed') if failed
    end
  end

end