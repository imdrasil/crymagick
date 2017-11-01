module CryMagick
  class Tempfile < IO::FileDescriptor
    ALLOWED_SYMBOLS       = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    FILE_CREATING_ATTEMPS = 238328
    TMP_DIR_PATH          = "/tmp"

    getter path : String

    def initialize(name : String, existing : Bool = false)
      oflag = LibC::O_RDWR | LibC::O_CREAT | LibC::O_APPEND | LibC::O_CLOEXEC
      @path = existing ? name : self.class.temp_file_path(name)
      fd = LibC.open(@path.check_no_null_byte, oflag, 420)
      raise Errno.new("Error opening tempfile '#{@path}'") if fd < 0
      super(fd, blocking: true)
    end

    def self.open(filename : String, &block)
      tempfile = Tempfile.new(filename)
      begin
        yield tempfile
      ensure
        tempfile.close
      end
      tempfile
    end

    def self.tmp_name(pattern : String) : String
      raise Errno.new("tmp_name (#{pattern})") if pattern.size < 6 || !pattern.includes?("XXXXXX")
      FILE_CREATING_ATTEMPS.times do
        part = "#{ALLOWED_SYMBOLS[rand(62)]}#{ALLOWED_SYMBOLS[rand(62)]}#{ALLOWED_SYMBOLS[rand(62)]}#{ALLOWED_SYMBOLS[rand(62)]}#{ALLOWED_SYMBOLS[rand(62)]}#{ALLOWED_SYMBOLS[rand(62)]}"
        new_path = pattern.sub("XXXXXX", part)
        next if File.exists?(new_path)
        return new_path
      end

      raise Error.new("No free tempfile name")
    end

    def self.temp_file_path(name : String) : String
      tmpdir = dirname + File::SEPARATOR
      Tempfile.tmp_name("#{tmpdir}XXXXXX.#{name}")
    end

    def self.dirname : String
      tmpdir = ENV["TMPDIR"]? || TMP_DIR_PATH
      tmpdir = tmpdir + File::SEPARATOR unless tmpdir.ends_with? File::SEPARATOR
      File.dirname(tmpdir)
    end

    def delete
      File.delete(@path)
    end

    def unlink
      delete
    end
  end

  module Utilities
    # Raise temp file with given dot-based extension
    def self.tempfile(ext : String) : CryMagick::Tempfile
      CryMagick::Tempfile.open("crymagick#{ext}") do |file|
        yield file
      end
    end

    def self.tempfile(ext) : CryMagick::Tempfile
      CryMagick::Tempfile.new("crymagick#{ext}")
    end

    # def gc
    # end
  end
end
