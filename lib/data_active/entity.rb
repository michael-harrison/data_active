module DataActive
  class Entity
    attr_reader :attributes
    attr_reader :klass
    attr_reader :associations
    attr_reader :tag_name
    attr_accessor :belongs_to

    def initialize(tag_name, options = [])
      @tag_name = tag_name
      @options = options
      @attributes = {}

      @klass = Kernel.const_get(@tag_name.camelize)
      raise "Class '#{@tag_name.camelize}' is not inherit ActiveRecord" unless @klass.ancestors.include? ActiveRecord::Base
      @associations = @klass.reflect_on_all_associations.map{ |a| a.plural_name }
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
      commit_record if options_include? :any, [:create,:update,:sync]
    end

    def commit_record
      existing_record = nil
      begin
        existing_record = @klass.find(@attributes[@klass.primary_key.to_s].content) if @attributes[@klass.primary_key.to_s].present?
      rescue
        existing_record = nil
      end

      @attributes.delete(@klass.primary_key.to_s)
      if existing_record.nil? and options_include? :any, [:create,:sync]
        commit_attibutes
        @record.save!
      elsif existing_record.present? and options_include? :any, [:update,:sync]
        @record = existing_record
        commit_attibutes
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