module DataActive
  class Attribute
    attr_reader :name
    attr_accessor :content
    attr_reader :known

    def initialize(name, known = true)
      @name = name
      @known = known
    end
  end
end