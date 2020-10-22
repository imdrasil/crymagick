module CryMagick
  # :nodoc:
  module Utilities
    # Yields temp file with given dot-based extension
    def self.tempfile(ext : String)
      ::File.tempfile("crymagick", ext) do |file|
        yield file
      end
    end

    def self.tempfile(ext)
      ::File.tempfile("crymagick", ext)
    end
  end
end
