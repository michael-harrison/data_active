require 'set'

module DataActive
  class Entity
    attr_reader :attributes
    attr_reader :klass
    attr_reader :associations
    attr_reader :tag_name
    attr_accessor :belongs_to
    attr_accessor :record
    attr_accessor :excluded

    def initialize(tag_name, options = [], excluded = false)
      @tag_name = tag_name
      @options = options
      @attributes = {}
      @associations = {}
      @excluded = excluded

      unless @excluded
        begin
          @klass = Kernel.const_get(@tag_name.camelize)
          raise "Class '#{@tag_name.camelize}' is not inherit ActiveRecord" unless @klass.ancestors.include? ActiveRecord::Base
          @associations = Hash[@klass.reflect_on_all_associations.map { |a| [a.plural_name.to_sym, a] }]
          @record = @klass.new
        rescue
          @excluded = true
        end
      end
    end


    def options_include? (context, options)
      ((@options & options).count.eql? options.count and  context.eql? :all) ||
        ((@options & options).count > 0 and  context.eql? :any)
    end

    def has_attribute?(name)
      if @excluded
        false
      else
        @record.attributes.include? name
      end
    end

    def has_association_with?(name)
      @associations.has_key? name.pluralize.to_sym
    end

    def commit
      id = nil
      existing_record = find_existing
      @attributes.delete(@klass.primary_key.to_s)

      if existing_record.nil? and options_include? :any, [:create, :sync]
        id = save
      elsif existing_record.present? and options_include? :any, [:update, :sync]
        @record = existing_record
        id = save
      elsif options_include? :any, [:destroy, :sync]
        id = @record.attributes[@klass.primary_key.to_s]
      end

      id
    end

    def update_associations
      if belongs_to.present? and not belongs_to.excluded
        association = belongs_to.klass.reflect_on_all_associations.select { |a| a.plural_name == @klass.name.underscore.pluralize }[0]
        if belongs_to.record.new_record?
          existing = belongs_to.find_existing
          belongs_to.record = existing if existing.present?
        end

        if belongs_to.record.new_record?
          case association.macro
            when :has_many, :has_many_and_blongs_to
              belongs_to.record.__send__(association.name) << @record

            when :has_one
              belongs_to.record.__send__("#{association.name}=", @record)

            else
              raise "unsupported association #{association.macro} for #{association.name} on #{@klass.name}"

          end
        else
          foreign_key = foreign_key_from(association)
          @record.__send__("#{foreign_key}=", belongs_to.record.__send__(belongs_to.klass.primary_key.to_sym))
        end
      end
    end

    def foreign_key_from(association)
      if ActiveRecord::Reflection::AssociationReflection.method_defined? :foreign_key
        # Support for Rails 3.1 and later
        foreign_key = association.foreign_key
      elsif ActiveRecord::Reflection::AssociationReflection.method_defined? :primary_key_name
        # Support for Rails earlier than 3.1
        foreign_key = association.primary_key_name
      else
        raise 'Unsupported version of ActiveRecord. Unable to identify the foreign key.'
      end
      foreign_key
    end

    def find_existing
      existing_record = nil

      begin
        existing_record = @klass.find(@attributes[@klass.primary_key.to_s].content) if @attributes[@klass.primary_key.to_s].present?
      rescue
        existing_record = nil
      end

      existing_record
    end

    def save
      commit_attributes
      update_associations

      if will_violate_association?
        @record.save!
        @record.attributes[@klass.primary_key.to_s]
      end
    end

    def will_violate_association?
      ok = true
      if belongs_to.present? and belongs_to.associations.count > 0
        if belongs_to.associations[@tag_name.pluralize.to_sym].macro == :has_one
          existing = belongs_to.record.__send__(@tag_name)
          if existing.present?
            if @record.__send__(@klass.primary_key.to_s) != existing.__send__(@klass.primary_key.to_s)
              ok = false
            end
          end
        end
      end

      ok
    end

    def commit_attributes
      @attributes.each do |key, a|
        @record.__send__("#{a.name}=", a.content)
      end
    end
  end
end