module CryMagick
  module Configuration
    class_property cli = :imagemagick,
      processor = :mogrify,
      cli_path = "",
      processor_path = "/usr/bin/mogrify",
      whiny = true,
      validate_on_write = true,
      validate_on_create = true

    def self.configure(&block)
      yield self
    end
  end
end
