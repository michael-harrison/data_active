require 'nokogiri'

module DataActive
  class SaxDocument < ::Nokogiri::XML::SAX::Document
    def initialize(first_element_name, options = {})
      @parser = DataActive::Parser.new(first_element_name, options)
    end

    def start_document

    end

    def end_document

    end

    def start_element_namespace

    end

    def end_element_namespace

    end

    def start_element(name, attr)
      @parser.begin(name)
    end

    def end_element(name)
      puts "end: #{name}"
    end

    def cdata_block(value)
      "text #{value}"
    end

    def characters(value)
      "text #{value}"
    end

    def error

    end
  end
end