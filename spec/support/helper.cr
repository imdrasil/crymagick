module Helper
  def image_path(type = :default)
    if type != :jpg_without_extension
      name = case type
             when :default, :jpg
               "default.jpg"
             when :png
               "engine.png"
             when :animation, :gif
               "animation.gif"
             when :exif
               "exif.jpg"
             when :empty_identity_line
               "empty_identity_line.png"
             when :badly_encoded_line
               "badly_encoded_line.jpg"
             when :not
               "not_an_image.cr"
             when :colon
               "with:colon.jpg"
             when :clipping_path
               "clipping_path.jpg"
             when :rgb
               "rgb.png"
             when :rgb_tmp
               "rgb_tmp.png"
             when :get_pixels
               "get_pixels.png"
             else
               raise "Image #{type} doesn't exist"
             end
      File.join("spec", "fixtures", name)
    else
      path = random_path
      FileUtils.cp image_path, path
      path
    end
  end

  def get_tempfile(path = "tempfile")
    File.tempfile(path)
  end

  def random_path(basename = "tempfile")
    tempfile = File.tempfile(basename)
    tempfile.path
  end

  def pack_array(array)
    io = IO::Memory.new
    array.each { |e| io.write_bytes(e) }
    io.to_s
  end
end
