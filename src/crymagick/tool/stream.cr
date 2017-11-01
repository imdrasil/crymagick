module CryMagick
  class Tool
    ##
    # @see http://www.imagemagick.org/script/stream.php
    #
    class Stream < CryMagick::Tool
      def initialize(options : Hash(Symbol, Bool) = {} of Symbol => Bool)
        super("stream", options)
      end

      def self.build(options : Hash(Symbol, Bool) = {} of Symbol => Bool)
        instance = new(options)
        yield instance
        instance.call
      end
    end
  end
end
