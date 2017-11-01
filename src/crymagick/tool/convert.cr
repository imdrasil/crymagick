module CryMagick
  class Tool
    class Convert < CryMagick::Tool
      def initialize(options = {} of Symbol => Bool)
        super("convert", options)
      end

      def self.build(options : Hash(Symbol, Bool) = {} of Symbol => Bool)
        instance = new(options)
        yield instance
        instance.call
      end
    end
  end
end
