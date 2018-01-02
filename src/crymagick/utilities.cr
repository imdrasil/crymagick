module CryMagick
  module Utilities
    # Raise temp file with given dot-based extension
    def self.tempfile(ext : String)
      ::Tempfile.open("crymagick#{ext}") do |file|
        yield file
      end
    end

    def self.tempfile(ext)
      ::Tempfile.new("crymagick", ext)
    end
  end
end
