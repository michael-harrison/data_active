module DataActive
  class Entity
    attr_reader :attributes
    attr_reader :klass
    attr_reader :associations
    attr_reader :tag_name

    def initialize(tag_name, options = [])
      @tag_name = tag_name
      @options = options
      @attributes = []

      @klass = Kernel.const_get(@tag_name.camelize)
      raise "Class '#{@tag_name.camelize}' is not inherit ActiveRecord" unless @klass.ancestors.include? ActiveRecord::Base
      @associations = @klass.reflect_on_all_associations.map{ |a| a.plural_name }
      @record = @klass.new
    end

    def has_attribute?(name)
      @record.attributes.include? name
    end

    def has_association_with?(name)
      @associations.include? name.pluralize
    end

    def commit

    end
  end
end