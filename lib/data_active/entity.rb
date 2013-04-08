module DataActive
  class Entity
    attr_reader :attributes
    attr_reader :klass
    attr_reader :associations
    attr_reader :tag_name
    attr_accessor :belongs_to
    attr_accessor :record

    def initialize(tag_name, options = [])
      @tag_name = tag_name
      @options = options
      @attributes = {}

      @klass = Kernel.const_get(@tag_name.camelize)
      raise "Class '#{@tag_name.camelize}' is not inherit ActiveRecord" unless @klass.ancestors.include? ActiveRecord::Base
      @associations = @klass.reflect_on_all_associations.map { |a| a.plural_name }
      @record = @klass.new
    end

    def options_include? (context, options)
      case context
        when :all
          (@options & options).count == options.count

        when :any
          (@options & options).count > 0
        else
          0
      end
    end

    def has_attribute?(name)
      @record.attributes.include? name
    end

    def has_association_with?(name)
      @associations.include? name.pluralize
    end

    def commit
      commit_record if options_include? :any, [:create, :update, :sync]
    end

    def update_associations
      if belongs_to.present?
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

    def commit_record
      existing_record = find_existing

      @attributes.delete(@klass.primary_key.to_s)
      if existing_record.nil? and options_include? :any, [:create, :sync]
        commit_attibutes
        update_associations
        @record.save!
      elsif existing_record.present? and options_include? :any, [:update, :sync]
        @record = existing_record
        commit_attibutes
        update_associations
        @record.save!
      end

    end

    def commit_attibutes
      @attributes.each do |key, a|
        @record.__send__("#{a.name}=", a.content)
      end
    end
  end
end