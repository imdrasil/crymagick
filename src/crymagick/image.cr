require "file_utils"

module CryMagick
  class Image
    alias Pixel = {UInt8, UInt8, UInt8}

    # =============================
    # static
    # =============================

    # Reads given string-based file with optional extension.
    def self.read(file : String, ext : String = "")
      create(ext) { |temp| temp.print(file) }
    end

    def self.read(file : IO, ext : String = "")
      create(ext) { |temp| temp.print(file.gets_to_end) }
    end

    # Creates new Image from given path
    #
    # TODO: allow to pass url
    def self.open(path : String, ext : String? = nil)
      raise "File is not exists" unless File.exists?(path)
      ext ||= File.extname(path)
      File.open(path) { |f| read(f, ext) }
    end

    # Creates tempfile and yields it for writing.
    def self.create(ext : String = "", validate : Bool = Configuration.validate_on_create)
      tempfile = CryMagick::Utilities.tempfile(ext.downcase) { |t| yield t }
      new(tempfile.path, tempfile).tap do |image|
        image.validate! if validate
      end
    end

    def self.import_pixels(blob : Array(Int), columns : Int, rows : Int, depth : Int, map : String | Symbol, format : String = "png")
      io = IO::Memory.new
      blob.each { |e| io.write_bytes(e) }
      import_pixels(io.to_slice, columns, rows, depth, map, format)
    end

    def self.import_pixels(blob : Slice(Int), columns : Int, rows : Int, depth : Int, map : String | Symbol, format : String = "png")
      target_image = create(".#{format}", false) {}
      create(".dat", false) { |f| f.write(blob) }.tap do |image|
        Tool::Convert.build do |convert|
          convert.size "#{columns}x#{rows}"
          convert.depth depth
          convert << "#{map}:#{image.path}"
          convert << target_image.path
        end
      end.destroy!

      target_image
    end

    getter path, tempfile : ::File?
    protected setter path

    def tempfile!
      @tempfile.not_nil!
    end

    def initialize(@path : String, @tempfile = nil)
      @info = Info.new(@path)
    end

    def ==(other : Image)
      signature == other.signature
    end

    def hash
      signature.hash
    end

    def valid?
      validate!
      true
    rescue CryMagick::Invalid
      false
    end

    def validate!
      identify
    rescue error : Error
      raise Invalid.new(error.message)
    end

    macro attribute(name, key = nil)
      {% _name = (key == nil) ? name : key %}
      def {{name.id}}
        @info.{{_name.id}}
      end
    end

    attribute :type, "format"
    attribute :mime_type
    attribute :width
    attribute :height
    attribute :dimensions
    attribute :size
    attribute :human_size
    attribute :colorspace
    attribute :exif
    attribute :signature
    attribute :data
    attribute :details

    def resolution(unit : String = "")
      @info.resolution(unit)
    end

    def [](value)
      @info[value.to_s]
    end

    def layers
      layers_count = identify.lines.size
      buf = [] of Image
      layers_count.times do |i|
        buf << Image.new("#{path}[#{i}]")
      end
      buf
    end

    def pages
      layers
    end

    def frames
      layers
    end

    def get_pixels
      convert = Tool::Convert.new
      convert << path
      convert.depth(8)
      convert << "RGB:-"

      # Do not use `convert.call` here. We need the whole binary (unstripped) output here.
      output, _status, _ = Shell.new.run(convert.command)

      slice = output.to_slice.to_a
      _width = width
      _height = slice.size / (3 * _width)
      position = 0

      Array(Array(Pixel)).new(_height.to_i) do |i|
        Array(Pixel).new(_width.to_i) do |j|
          temp = {slice[position], slice[position + 1], slice[position + 2]}
          position += 3
          temp
        end
      end
    end

    # page = -1 for all frames
    #
    # TODO: fix converting several frames - point current image to first one (now it points to empty img)
    def format(_format, page : String = "0", read_options : Hash(String, String) = {} of String => String)
      new_temp_file = nil
      new_path =
        if @tempfile
          new_temp_file = Utilities.tempfile(".#{_format}")
          new_temp_file.path
        else
          parts = path.split(".")
          (parts.size == 1 ? parts[0] : parts[0...-1].join(""))  + ".#{_format}"
        end
      input_path = path.clone
      input_path += "[#{page}]" if page != "-1" && !layer?

      Tool::Convert.build do |con|
        read_options.each do |key, value|
          con.send(key, value)
        end

        con << input_path
        yield con
        con << new_path
      end

      if @tempfile
        destroy!
        @tempfile = new_temp_file.not_nil!
      else
        File.delete(path) unless path == new_path || layer?
      end
      @path = new_path
      @info.clear
      @info = Info.new(@path)

      self
    end

    def format(_format, page : String = "0", read_options : Hash(String, String) = {} of String => String)
      format(_format, page, read_options) { }
    end

    def combine_options
      mogrify { |m| yield m }
    end

    def write(output_to : String)
      if layer?
        Tool::Convert.build do |builder|
          builder << path
          builder << output_to
        end
      else
        FileUtils.cp(path, output_to) unless path == output_to
      end
    end

    def write(output : IO)
      output.print(File.read(path))
    end

    def composite(other_image, output_ext = type.downcase, mask : String? = nil)
      output_tempfile = Utilities.tempfile(".#{output_ext}")

      Tool::Composite.build do |comp|
        yield comp
        comp << other_image.path
        comp << path
        comp << mask.path if mask
        comp << output_tempfile.path
      end

      Image.new(output_tempfile.path, output_tempfile)
    end

    def composite(other_image, output_ext = type.downcase, mask : String? = nil)
      composite(other_image, output_ext, mask) { }
    end

    def collapse!(frame : Int32 = 0)
      mogrify(frame) { |builder| builder.quality(100) }
    end

    def destroy!
      return unless @tempfile
      FileUtils.rm_rf(tempfile!.path.sub(/mpc$/, "cache")) if tempfile!.path.ends_with?(".mpc")
      tempfile!.delete
    end

    def identify
      Tool::Identify.build do |builder|
        builder << path
      end
    end

    def identify(&block)
      Tool::Identify.build do |builder|
        yield builder
        builder << path
      end
    end

    def mogrify(page : Int32? = nil)
      mogrify(page) { }
    end

    def mogrify(page : Int32? = nil)
      Tool::Mogrify.build do |builder|
        yield builder
        builder << (page ? "#{path}[#{page.to_s}]" : path)
      end
      @info.clear
      self
    end

    def layer?
      path =~ /\[\d+\]$/
    end

    def run_command(tool_name : String, *args)
      Tool.build(tool_name) do |builder|
        args.each do |arg|
          builder << arg
        end
      end
    end

    macro method_missing(call)
      def {{call.name.id}}(*args)
        mogrify do |builder|
          builder.{{call.name.id}}(*args)
        end
      end
    end
  end
end

require "./image/info"
