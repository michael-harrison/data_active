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
      parser.begin('book')

      parser.begin('id')
      parser.content('1')
      parser.end('id')

      parser.begin('name')
      parser.content('101 Testing')
      parser.end('name')

      # Unknown attribute
      parser.begin('full_name')
      parser.content('101 Testing: Your start to testing')
      parser.end('full_name')

      parser.stack.last.attributes[0].name.should eq 'id'
      parser.stack.last.attributes[0].content.should eq '1'
      parser.stack.last.attributes[1].name.should eq 'name'
      parser.stack.last.attributes[1].content.should eq '101 Testing'
      parser.stack.last.attributes.select{ |a| a.name == 'full_name' }.count.should eq 0
    end

    it ('should raise an error when strict mode is used') do
      parser.options << :strict
      parser.begin('book')
      failed = true
      begin
        parser.begin('bogus')
        parser.content('1')
        parser.end('bogus')
      rescue
        failed = false
      end
      fail('Element that was not either an attribute or association was allowed') if failed
    end

    it ('should all unknown element when not in strict mode') do
      parser.begin('book')
      parser.begin('bogus')
      parser.content('1')
      parser.end('bogus')
    end
  end

  context 'when parsing associations' do
    let (:parser) { DataActive::Parser.new('book') }
    it ('will get upset about mismatched tags') do
      parser.begin('book')

      parser.begin('id')
      parser.content('1')
      parser.end('id')
      failed = true
      begin
        parser.end('chapter')
      rescue
        failed = false
      end

      fail('Allowed mismatched tags') if failed

    end
    it ('should parse all associations known and unknown') do
      parser.begin('book')
      parser.begin('id')
      parser.content('1')
      parser.end('id')

      parser.begin('chapter')
      parser.stack.last.klass.name.should eq 'Chapter'
      parser.begin('id')
      parser.content('2')
      parser.end('id')
      parser.begin('title')
      parser.content('20/20 hindsight')
      parser.end('title')
      parser.end('chapter')

      parser.begin('appendix')
      parser.begin('id')
      parser.content('3')
      parser.end('id')
      parser.begin('name')
      parser.content('Appendix A - Swimming Rules')
      parser.end('name')
      parser.begin('body')
      parser.content('some swimming rules')
      parser.end('body')
      parser.end('appendix')

      parser.begin('chapter')
      parser.stack.last.klass.name.should eq 'Chapter'
      parser.begin('id')
      parser.content('3')
      parser.end('id')
      parser.begin('title')
      parser.content('The future')
      parser.end('title')
      parser.end('chapter')

      parser.end('book')
    end

    it ('should parse only known associations when in strict mode') do
      parser.options << :strict
      parser.begin('book')
      parser.begin('id')
      parser.content('1')
      parser.end('id')

      parser.begin('chapter')
      parser.stack.last.klass.name.should eq 'Chapter'
      parser.begin('id')
      parser.content('2')
      parser.end('id')
      parser.begin('title')
      parser.content('20/20 hindsight')
      parser.end('title')
      parser.end('chapter')

      failed = true
      begin
        parser.begin('appendix')
        parser.begin('id')
        parser.content('3')
        parser.end('id')
        parser.begin('name')
        parser.content('Appendix A - Swimming Rules')
        parser.end('name')
        parser.begin('body')
        parser.content('some swimming rules')
        parser.end('body')
      rescue
        failed = false
      end
      fail('Element that was not either an attribute or association was allowed') if failed
    end
  end

end