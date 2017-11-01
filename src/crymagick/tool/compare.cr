module CryMagick
  class Tool
    # For more details visit
    # [page](see http://www.imagemagick.org/script/compare.php)
    #
    class Compare < CryMagick::Tool
      def initialize(options : Hash(Symbol, Bool) = {} of Symbol => Bool)
        super("compare", options)
      end

      def self.build(options : Hash(Symbol, Bool) = {} of Symbol => Bool)
        instance = new(options)
        yield instance
        instance.call
      end
    end
  end
end
