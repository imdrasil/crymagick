module CryMagick
  class Tool
    class Composite < CryMagick::Tool
      def initialize(options = {} of Symbol => Bool)
        super("composite", options)
      end

      def self.build(options : Hash(Symbol, Bool) = {} of Symbol => Bool)
        instance = new(options)
        yield instance
        instance.call
      end
    end
  end
end
