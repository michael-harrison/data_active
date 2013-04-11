module DataActive
  class Parser
    attr_accessor :options
    attr_reader :stack
    attr_reader :first_element_name

    def initialize(first_element_name, options = [])
      @options = options
      @stack = []
      @first_element_name = first_element_name
      @started_parsing = false
    end

    def begin(name)
      @started_parsing = (@first_element_name == name) if not @started_parsing
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
      elsif parent.excluded
        @stack << DataActive::Attribute.new(name, false)
      else
        raise "Unknown element '#{name}' for #{parent.klass.name}" if @options.include? :strict
        @stack << DataActive::Attribute.new(name, false)
      end
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
        @stack.last.content = value
      end

      self
    end

    def end(name)
      case @stack.last.class.name
        when 'DataActive::Entity'
          raise "Mismatched closing tag '#{name}' when opening tag was #{@stack.last.tag_name}" unless @stack.last.tag_name.eql? name
          entity = @stack.pop()
          entity.commit() if not entity.excluded

        when 'DataActive::Attribute'
          raise "Mismatched closing tag '#{name}' when opening tag was #{@stack.last.name}" unless @stack.last.name.eql? name
          attribute = @stack.pop()
          @stack.last.attributes[attribute.name] = attribute if attribute.known

        else
          raise "Unhandled class '#{@stack.last.class.name}'"
      end

      self
    end

    def has_started_parsing?
      @started_parsing
    end
  end
end