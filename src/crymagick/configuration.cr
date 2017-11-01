require "logger"

module CryMagick
  module Configuration
    # [logger, Logger?, nil]
    macro class_property(name, type, default)
      {% name = name.id %}

      @@{{name}} : {{type}} = {{default}}

      def self.{{name}}
        @@{{name}}
      end

      def self.{{name}}=(value : {{type}})
        @@{{name}} = value
      end
    end

    {% for option in [
                       ["cli", Symbol, :imagemagick],
                       ["processor", Symbol, :mogrify],
                       ["cli_path", String, ""],
                       ["processor_path", String, "/usr/bin/mogrify"],
                       ["whiny", Bool, true],
                       ["validate_on_write", Bool, true],
                       ["validate_on_create", Bool, true],
                     ] %}

      class_property({{option[0]}}, {{option[1]}}, {{option[2]}})
    {% end %}

    def self.configure(&block)
      yield self
    end
  end
end
