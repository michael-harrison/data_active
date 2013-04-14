module DataActive
  class Parser
    attr_accessor :options
    attr_reader :stack
    attr_reader :first_element_name
    attr_reader :root_klass

    def initialize(first_element_name, options = [])
      @options = options
      @stack = []
      @first_element_name = first_element_name
      @started_parsing = false
      @processed_entities = {}
      @root_klass = nil
    end

    def options_include? (context, options)
      ((@options & options).count.eql? options.count and context.eql? :all) ||
        ((@options & options).count > 0 and context.eql? :any)
    end

    def begin(name)
      if not @started_parsing and @first_element_name == name
        @started_parsing = true
        begin
          @root_klass = Kernel.const_get(name.camelize)
        rescue
          raise "Unable to find class for '#{name}'"
        end
      end

      process_element(name)

      self
    end

    def process_element(name)
      if @stack.last.nil?
        @stack << DataActive::Entity.new(name, @options, !@started_parsing)
      elsif @stack.last.class.name == 'DataActive::Entity'
        process_entity_child(name)
      elsif @stack.last.class.name == 'DataActive::Attribute' and not @stack.last.known
        @stack << DataActive::Attribute.new(name, false)
      end
    end

    def process_entity_child(name)
      parent = @stack.last
      if parent.has_association_with? name or parent.tag_name == name.pluralize
        create_child_entity(name)
      elsif parent.has_attribute? name
        @stack << DataActive::Attribute.new(name)
      elsif klass_exists? name
        create_child_entity(name)
      elsif parent.excluded
        @stack << DataActive::Attribute.new(name, false)
      else
        raise "Unknown element '#{name}' for #{parent.klass.name}" if @options.include? :strict
        @stack << DataActive::Attribute.new(name, false)
      end
    end

    def klass_exists? name
      is_klass = true

      begin
        klass = Kernel.const_get(name.camelize)
        fail unless klass.ancestors.include? ActiveRecord::Base
      rescue
        is_klass = false
      end

      is_klass
    end

    def create_child_entity(name)
      entity = DataActive::Entity.new(name, @options, !@started_parsing)

      if @stack.last.tag_name == name.pluralize
        entity.belongs_to = @stack.last.belongs_to
      else
        entity.belongs_to = @stack.last
      end

      @stack << entity
    end

    def content(value)
      if @stack.last.class.name == 'DataActive::Entity'
        raise "'#{@stack.last.tag_name}' contains text '#{value}'" if value.strip.length > 0
      else
        @stack.last.content = @stack.last.content.nil? ? value : @stack.last.content + value
      end

      self
    end

    def end(name)
      case @stack.last.class.name
        when 'DataActive::Entity'
          end_entity(name)

        when 'DataActive::Attribute'
          end_attribute(name)

        else
          raise "Unhandled class '#{@stack.last.class.name}'"
      end

      self
    end

    def end_attribute(name)
      raise "Mismatched closing tag '#{name}' when opening tag was #{@stack.last.name}" unless @stack.last.name.eql? name
      attribute = @stack.pop()
      @stack.last.attributes[attribute.name] = attribute if attribute.known
    end

    def end_entity(name)
      raise "Mismatched closing tag '#{name}' when opening tag was #{@stack.last.tag_name}" unless @stack.last.tag_name.eql? name
      entity = @stack.pop()
      store_processed_entity_id(entity.klass, entity.commit()) if not entity.excluded
    end

    def destroy(klass = self.root_klass)
      @destroyed ||= []
      if options_include? :any, [:destroy, :sync]
        klass.reflect_on_all_associations.each do |a|
          if [:has_many, :has_many_and_belongs_to, :has_one].include? a.macro and @destroyed.exclude? a.klass.name
            @destroyed << a.klass.name
            destroy(a.klass)
          end
        end

        destroy_records(klass)
        @destroyed << klass.name
      end
    end

    def destroy_records(klass)
      ids = @processed_entities[klass.name.to_sym]
      ids.nil? ? klass.destroy_all : klass.destroy_all([klass.primary_key.to_s + ' not in (?)', ids.collect])
    end

    def store_processed_entity_id(klass, id)
      return if id.nil?

      if @processed_entities[klass.name.to_sym].present?
        @processed_entities[klass.name.to_sym] << id
      else
        @processed_entities[klass.name.to_sym] = [id]
      end
    end

    def has_started_parsing?
      @started_parsing
    end
  end
end