require 'data_active/version'
require 'data_active/entity'
require 'data_active/sax_document'
require 'data_active/parser'
require 'data_active/attribute'

module DataActive
  def self.included(base)
    base.extend ClassMethods
  end

  def ensure_unique(name)
    begin
      self[name] = yield
    end while self.class.exists?(name => self[name])
  end

  VALID_FROM_XML_OPTIONS = [:sync, :create, :update, :destroy, :fail_on_invalid]

  module ClassMethods
    def many_from_xml(source_xml, options = [])
      parser = Nokogiri::XML::SAX::Parser.new(DataActive::SaxDocument.new(self.name.underscore, options))
      parser.parse(source_xml)
    end

    def one_from_xml(source_xml, options = [])
      parser = Nokogiri::XML::SAX::Parser.new(DataActive::SaxDocument.new(self.name.underscore, options))
      parser.parse(source_xml)
    end
  end
end

class ActiveRecord::Base
  include DataActive
end
