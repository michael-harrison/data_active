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
      if has_started_parsing?
        if @stack.last.class.name == 'DataActive::Entity'
          if @stack.last.tag_name == name.pluralize
            entity = DataActive::Entity.new(name, @options)
            if @stack.last.tag_name == name.pluralize
              entity.belongs_to = @stack.last.belongs_to
            else
              entity.belongs_to = @stack.last
            end
            @stack << entity
          elsif @stack.last.has_attribute? name
            @stack << DataActive::Attribute.new(name)
          elsif @stack.last.has_association_with? name
            entity = DataActive::Entity.new(name, @options)
            entity.belongs_to = @stack.last

            @stack << entity
          else
            raise "Unknown element '#{name}' for #{@stack.last.klass.name}" if @options.include? :strict
            @stack << DataActive::Attribute.new(name, false)
          end
        elsif @stack.last.class.name == 'DataActive::Attribute' and not @stack.last.known
          @stack << DataActive::Attribute.new(name, false)
        end
      else
        @stack << DataActive::Entity.new(name, @options, @first_element_name != name)
        @started_parsing = (@first_element_name == name)
      end

      self
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