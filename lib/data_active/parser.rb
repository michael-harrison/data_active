module DataActive
  class Parser
    attr_accessor :options
    attr_reader :stack
    attr_reader :first_element_name

    def initialize(first_element_name, options = [])
      @options = options
      @stack = []
      @first_element_name = first_element_name
    end

    def begin(name)
      if has_started_parsing?
        if @stack.last.class.name == 'DataActive::Entity'
          if @stack.last.has_attribute? name
            @stack << DataActive::Attribute.new(name)
          elsif @stack.last.has_association_with? name
            @stack << DataActive::Entity.new(name, @options)
          else
            raise "Unknown element '#{name}' for #{@stack.last.klass.name}" if @options.include? :strict
            @stack << DataActive::Attribute.new(name, false)
          end
        elsif @stack.last.class.name == 'DataActive::Attribute' and not @stack.last.known
          @stack << DataActive::Attribute.new(name, false)
        end
      else
        @stack << DataActive::Entity.new(name, @options) if @first_element_name == name
      end
    end

    def content(value)
      raise "'#{@stack.last.klass.name}' contains text" if @stack.last.class.name == 'DataActive::Entity'
      @stack.last.content = value
    end

    def end(name)
      case @stack.last.class.name
        when 'DataActive::Entity'
          raise "Mismatched closing tag '#{name}' when opening tag was #{@stack.last.tag_name}" unless @stack.last.tag_name.eql? name
          entity = @stack.pop()
          entity.commit()

        when 'DataActive::Attribute'
          raise "Mismatched closing tag '#{name}' when opening tag was #{@stack.last.name}" unless @stack.last.name.eql? name
          attribute = @stack.pop()
          @stack.last.attributes << attribute if attribute.known

        else
          raise "Unhandled class '#{@stack.last.class.name}'"
      end

    end

    def has_started_parsing?
      @stack.count > 0
    end
  end
end