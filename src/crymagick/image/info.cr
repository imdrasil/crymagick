require "json"

module CryMagick
  class Image
    class Info
      ASCII_ENCODED_EXIF_KEYS = %w(ExifVersion FlashPixVersion)
      ALL_ATTRS               = %w(format mime_type width height dimensions size human_size colorspace mime_type exif resolution signature details)
      STRING_ATTRS            = %w(format mime_type human_size colorspace signature details)
      INT_ATTR                = %w(width height)

      @dimensions : Tuple(Int32, Int32)?
      @size : UInt64?
      @exif : Hash(String, String)?
      @data : Hash(String, JSON::Any)?
      @details : Hash(String, Hash(String, String))?

      {% for var in STRING_ATTRS %}
        @{{var.id}} : String?
      {% end %}

      {% for var in INT_ATTR %}
        @{{var.id}} : Int32?
      {% end %}

      def initialize(@path : String)
        @info = {} of String => String
        @resolution = {} of String => Tuple(Float64, Float64)
      end

      def [](value, *args)
        _value = value.to_s
        {% for attr in ALL_ATTRS %}
          return {{attr.id}} if _value == "{{attr.id}}"
        {% end %}
        raw(value)
      end

      def clear
        @info.clear
        @resolution.clear
        @data = nil
        {% for attr in ALL_ATTRS %}
          {% if attr != "resolution" %}
            @{{attr.id}} = nil
          {% end %}
        {% end %}
      end

      def mime_type
        "image/#{format.downcase}"
      end

      def colorspace
        @colorspace ||= raw("%r")
      end

      def exif
        @exif ||= begin
          hash = {} of String => String
          output = raw("%[EXIF:*]")

          output.each_line do |line|
            line = line.chomp("\n")

            case Configuration.cli
            when :imagemagick
              if match = line.match(/^exif:/)
                key, value = match.post_match.split("=", 2)
                value = decode_comma_separated_ascii_characters(value) if ASCII_ENCODED_EXIF_KEYS.includes?(key)
                hash[key] = value
              else
                hash[hash.keys.last] += "\n#{line}"
              end
            when :graphicsmagick
              key, value = line.split("=", 2)
              hash[key] = value.gsub("\\012", "\n") # convert "\012" characters to newlines
            end
          end

          hash
        end
      end

      def resolution(unit = "")
        @resolution[unit] ||= begin
          output = identify do |b|
            b.units(unit) unless unit.empty?
            b.format("%x %y")
          end
          values = output.split(" ")
          {values[0].to_f, values[1].to_f}
        end
      end

      def signature
        @signature ||= raw("%#")
      end

      def details
        raise "Not implemented yet"
      end

      def data
        @data ||= begin
          json = Tool::Convert.build do |convert|
            convert << path
            convert << "json:"
          end

          data = JSON.parse(json)
          (data.as_a? ? data[0]["image"] : data["image"]).as_h
        end
      end

      {% for attr in %w(format width height dimensions size human_size) %}
        def {{attr.id}}
          return @{{attr.id}}.not_nil! if @{{attr.id}}
          cheap_info({{attr}})
          @{{attr.id}}.not_nil!
        end
      {% end %}

      def cheap_info(value)
        format, width, height, size = self["%m %w %h %b"].as(String).split(" ")

        path = @path
        path = path.match(/\[\d+\]$/).not_nil!.pre_match if path =~ /\[\d+\]$/
        @format = format
        @width = width.to_i
        @height = height.to_i
        @dimensions = {@width.not_nil!, @height.not_nil!}
        @size = File.size(path).to_u64
        @human_size = size
      end

      def raw(value)
        @info["raw:#{value}"] ||= identify(&.format(value))
      end

      def raw_exif(value)
        raw("%[#{value}]")
      end

      def identify : String
        Tool::Identify.build do |builder|
          yield builder
          builder << path
        end
      end

      private def path
        value = @path
        value += "[0]" unless value =~ /\[\d+\]$/
        value
      end

      private def decode_comma_separated_ascii_characters(encoded_value)
        return encoded_value unless encoded_value.includes?(",")
        arr = [] of Char
        res = encoded_value.scan(/\d+/)
        res.each do |entry|
          arr << entry[0].to_i.chr
        end
        arr.join
      end
    end
  end
end
