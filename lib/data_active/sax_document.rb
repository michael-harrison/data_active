require 'nokogiri'

module DataActive
  class SaxDocument < ::Nokogiri::XML::SAX::Document
    def initialize(first_element_name, options = {})
      @parser = DataActive::Parser.new(first_element_name, options)
    end

    def start_element(name, attr)
      @parser.begin(name)
    end

    def end_element(name)
      @parser.end(name)
    end

    def cdata_block(value)
      @parser.content(value)
    end

    def characters(value)
      @parser.content(value)
    end

    def end_document
      @parser.destroy
    end
  end
end