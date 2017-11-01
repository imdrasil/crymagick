require "../spec_helper"

describe CryMagick::Image do
  let(:described_class) { CryMagick::Image }
  @subject : CryMagick::Image?
  let(:subject) { CryMagick::Image.open(image_path) }

  describe ".read" do
    it "reads image from String" do
      string = File.read(image_path)
      image = described_class.read(string)
      expect(image.valid?).must_equal(true)
    end

    it "reads image from tempfile" do
      tempfile = get_tempfile
      FileUtils.cp(image_path, tempfile.path)
      image = described_class.read(tempfile)
      expect(image.valid?).must_equal(true)
    end
  end

  describe ".open" do
    it "makes a copy of the image" do
      image = described_class.open(image_path)
      expect(image.path).wont_equal image_path
      expect(image.valid?).must_equal true
    end

    it "accepts a string" do
      image = described_class.open(image_path)
      expect(image.valid?).must_equal true
    end

    # it "loads a remote image" do
    #  begin
    #    image = described_class.open(image_url)
    #    expect(image).to be_valid
    #  rescue SocketError
    #  end
    # end

    it "validates the image" do
      assert_raises(CryMagick::Invalid) do
        described_class.open(image_path(:not))
      end
    end

    it "does not mistake a path with a colon for a URI schema" do
      described_class.open(image_path(:colon))
    end
  end

  describe ".create" do
    def create(path = image_path)
      described_class.create do |f|
        f.print(File.read(path))
      end
    end

    it "creates an image" do
      image = create
      expect(File.exists?(image.path)).must_equal true
    end

    it "validates the image if validation is set" do
      assert_raises(CryMagick::Invalid) do
        create(image_path(:not))
      end
    end

    it "doesn't validate image if validation is disabled" do
      begin
        CryMagick::Configuration.validate_on_create = false
        create(image_path(:not))
      ensure
        CryMagick::Configuration.validate_on_create = true
      end
    end
  end

  describe "equivalence" do
    @image : CryMagick::Image?
    @same_image : CryMagick::Image?
    @other_image : CryMagick::Image?
    let(:image) { described_class.new(image_path) }
    let(:same_image) { described_class.new(image_path) }
    let(:other_image) { described_class.new(image_path(:exif)) }

    it "is #== to itself" do
      expect(image).must_equal(image)
    end

    it "is #== to an instance of the same image" do
      expect(image).must_equal(same_image)
    end

    it "is not #== to an instance of a different image" do
      expect(image).wont_equal(other_image)
    end

    it "generates the same hash code for an instance of the same image" do
      expect(image.hash).must_equal(same_image.hash)
    end

    it "generates different same hash codes for a different image" do
      expect(image.hash).wont_equal(other_image.hash)
    end
  end

  describe "#tempfile" do
    it "returns the underlying temporary file" do
      image = described_class.open(image_path)
      expect(image.tempfile).wont_be_nil
    end
  end

  describe "#valid?" do
    it "returns true when image is valid" do
      image = described_class.new(image_path)
      expect(image.valid?).must_equal(true)
    end

    it "returns false when image is not valid" do
      image = described_class.new(image_path(:not))
      expect(image.valid?).must_equal(false)
    end
  end

  it "create temfile" do
    file = described_class.open("spec/fixtures/cylinder_shaded.png")
    expect(File.exists?(file.path)).must_equal(true)
  end

  describe "#write" do
    it "writes the image" do
      output_path = random_path("test output")
      subject.write(output_path)
      expect(described_class.new(output_path).valid?).must_equal(true)
    end

    it "writes an image with stream" do
      output_stream = IO::Memory.new
      subject.write(output_stream)
      expect(described_class.read(output_stream.to_s).valid?).must_equal(true)
    end

    it "writes layers" do
      output_path = random_path(".#{subject.type.downcase}")
      subject = described_class.new(image_path(:gif))
      subject.frames.first.write(output_path)
      expect(described_class.new(output_path).valid?).must_equal(true)
    end

    it "works when writing to the same path" do
      subject.write(subject.path)
      expect(File.read(subject.path)).wont_be_empty
    end
  end

  describe "#format" do
    let(:subject) { described_class.open(image_path(:jpg)) }

    it "changes the format of the photo" do
      expect_to_change(->{ subject.type }) do
        subject.format("png")
      end
    end

    it "reformats an image with a given extension" do
      expect_to_change(->{ File.extname(subject.path) }, to: ".png") do
        subject.format(:png)
      end
    end

    it "creates the file with new extension" do
      subject.format(:png)
      expect(File.exists?(subject.path)).must_equal(true)
    end

    it "accepts a block of additional commands" do
      expect_to_change(->{ subject.dimensions }, to: {100, 100}) do
        subject.format(:png) do |b|
          b.resize("100x100!")
        end
      end
    end

    it "works without an extension with .open" do
      subject = described_class.open(image_path(:jpg_without_extension))
      subject.format("png")

      expect(File.extname(subject.path)).must_equal ".png"
      expect(subject.type).must_equal "PNG"
    end

    it "works without an extension with .new" do
      subject = described_class.new(image_path(:jpg_without_extension))
      subject.format("png")

      expect(File.extname(subject.path)).must_equal ".png"
      expect(subject.type).must_equal "PNG"
    end

    it "deletes the previous tempfile" do
      old_path = subject.path.dup
      subject.format(:png)
      expect(File.exists?(old_path)).must_equal false
    end

    it "deletes *.cache files generated from .mpc" do
      image = described_class.open(image_path)
      image.format("mpc")
      cache_path = image.path.sub(/mpc$/, "cache")
      image.format("png")

      expect(File.exists?(cache_path)).must_equal false
    end

    it "doesn't delete itself when formatted to the same format" do
      subject.format(subject.type.downcase)
      expect(File.exists?(subject.path)).must_equal true
    end

    it "reformats multi-image formats to multiple images" do
      subject = described_class.open(image_path(:animation))
      subject.format(:jpg, "-1")

      expect(Dir[subject.path.sub(/\..+$/, ".*")].size).must_equal 21
    end

    it "reformats multi-image formats to a single image" do
      subject = described_class.open(image_path(:animation))
      subject.format("jpg")
      expect(subject.valid?).must_equal true
    end

    it "reformats a layer" do
      subject = described_class.open(image_path(:animation))
      layer = subject.layers.first
      layer.format("jpg")
      expect(layer.valid?).must_equal true
      expect(layer.path[/\..+$/]).must_equal ".jpg"
      expect(File.exists?(layer.path)).must_equal true
    end

    it "clears the info only at the end" do
      subject.format("png") { subject.type }
      expect(subject.type).must_equal "PNG"
    end

    it "returns self" do
      expect(subject.format("png")).must_equal subject
    end

    it "reads read_opts from passed arguments" do
      subject = described_class.open(image_path(:animation))
      layer = subject.layers.first
      layer.format("jpg", "-1", {"density" => "300"})
      expect(layer.valid?).must_equal true
    end
  end

  describe "#braces" do
    it "inspects image meta info" do
      expect_be_a(subject[:width], Int32)
      expect_be_a(subject[:height], Int32)
      expect_be_a(subject[:colorspace], String)
      expect(subject[:format]).must_match(/[A-Z]/)
      expect(subject[:signature]).must_match(/[[:alnum:]]{64}/)
    end

    it "supports string keys" do
      expect_be_a(subject["width"], Int32)
      expect_be_a(subject["height"], Int32)
      expect_be_a(subject["colorspace"], String)
      expect(subject["format"]).must_match(/[A-Z]/)
      expect(subject["signature"]).must_match(/[[:alnum:]]{64}/)
    end

    it "reads exif" do
      subject = described_class.new(image_path(:exif))
      expect(subject["EXIF:Flash"]).wont_equal "0"
    end

    it "passes unknown values directly to -format" do
      expect(subject["%w %h"].as(String).split.map(&.to_i)).must_equal [subject[:width], subject[:height]]
    end
  end

  it "has attributes" do
    expect(subject.type).must_match(/^[A-Z]+$/)
    expect(subject.mime_type).must_match(/^image\/[a-z]+$/)
    expect(subject.width).wont_equal(0)
    expect(subject.height).wont_equal(0)
    subject.dimensions
    expect(subject.size).wont_equal(0)
    expect(subject.human_size).wont_be_empty
    expect_be_a(subject.colorspace, String)
    expect_be_a(subject.resolution, Tuple(Float64, Float64))
    expect(subject.signature).must_match(/[[:alnum:]]{64}/)
  end

  it "generates attributes of layers" do
    expect(subject.layers[0].type).must_match(/^[A-Z]+$/)
    expect(subject.layers[0].size > 0).must_equal true
  end

  it "changes colorspace when called with an argument" do
    # TODO: add correct expectation
    subject.colorspace("Gray")
  end

  it "changes size when called with an argument" do
    # TODO: add correct expectation
    subject.size("20x20")
  end

  describe "#exif" do
    let(:subject) { described_class.new(image_path(:exif)) }

    it "returns a hash of EXIF data" do
      expect_be_a(subject.exif["DateTimeOriginal"], String)
    end
  end

  describe "#resolution" do
    it "accepts units" do # skip_cli: :graphicsmagick
      expect(subject.resolution("PixelsPerCentimeter"))
        .wont_equal subject.resolution("PixelsPerInch")
    end
  end

  describe "#mime_type" do
    it "returns the correct mime type" do
      jpg = described_class.new(image_path(:jpg))
      expect(jpg.mime_type).must_equal "image/jpeg"
    end
  end

  describe "#details" do
    # TODO: add after implementation
  end

  describe "#data" do
    # TODO: add after implementation
  end

  describe "#layers" do
    it "returns a list of images" do
      expect_be_a(subject.layers, Array(CryMagick::Image))
      expect(subject.layers.first.valid?).must_equal true
    end

    it "returns multiple images for GIFs, PDFs and PSDs" do
      gif = described_class.new(image_path(:gif))

      expect(gif.layers.size > 1).must_equal true
      expect(gif.frames.size > 1).must_equal true
      expect(gif.pages.size > 1).must_equal true
    end

    it "returns one image for other formats" do
      jpg = described_class.new(image_path(:jpg))

      expect(jpg.layers.size).must_equal 1
    end
  end

  describe "#combine_options" do
    it "chains multiple options and executes them in one command" do
      expect_to_change(->{ subject.dimensions }, to: {20, 30}) do
        subject.combine_options { |c| c.resize "20x30!" }
      end
    end

    it "clears the info only at the end" do
      subject.combine_options { |c| c.resize("20x30!"); subject.width }
      expect(subject.dimensions).must_equal({20, 30})
    end

    it "returns self" do
      expect(subject.combine_options { }).must_equal subject
    end
  end

  describe "#composite" do
    @other_image : CryMagick::Image?
    @mask : CryMagick::Image?
    let(:other_image) { described_class.open(image_path) }
    let(:mask) { described_class.open(image_path) }

    it "creates a composite of two images" do
      image = subject.composite(other_image)
      expect(image.valid?).must_equal true
    end

    it "creates a composite of two images with mask" do
      image = subject.composite(other_image, "jpg", mask)
      expect(image.valid?).must_equal true
    end

    it "makes the composited image with the provided extension" do
      result = subject.composite(other_image, "png")
      expect(result.path.ends_with?(".png")).must_equal true
    end

    it "defaults the extension to the extension of the base image" do
      subject = described_class.open(image_path(:jpg))
      result = subject.composite(other_image)
      expect(result.path.ends_with? ".jpeg").must_equal true

      subject = described_class.open(image_path(:gif))
      result = subject.composite(other_image)
      expect(result.path.ends_with? ".gif").must_equal true
    end
  end

  describe "#collapse!" do
    let(:subject) { described_class.open(image_path(:animation)) }

    it "collapses the image to one frame" do
      subject.collapse!
      expect(subject.identify.lines.size).must_equal 1
    end

    it "keeps the extension" do
      expect_not_to_change(->{ subject.type }) do
        subject.collapse!
      end
    end

    it "clears the info" do
      expect_to_change(->{ subject.size }) do
        subject.collapse!
      end
    end

    it "returns self" do
      expect(subject.collapse!).must_equal subject
    end
  end

  describe "#destroy!" do
    it "deletes the underlying tempfile" do
      image = described_class.open(image_path)
      image.destroy!

      expect(File.exists?(image.path)).must_equal false
    end

    it "doesn't delete when there is no tempfile" do
      image = described_class.new(image_path)
      image.destroy!

      expect(File.exists?(image.path)).must_equal true
    end

    it "deletes .cache files generated by handling .mpc files" do
      image = described_class.open(image_path)
      image.format("mpc")
      image.destroy!

      expect(File.exists?(image.path.sub(/mpc$/, "cache"))).must_equal false
    end
  end

  describe "#identify" do
    it "returns the output of identify" do
      expect(subject.identify).must_match(subject.type)
    end

    it "yields an optional block" do
      output = subject.identify do |b|
        b.verbose
      end
      expect(output).must_match("Format:")
    end
  end

  describe "#run_command" do
    it "runs the given command" do
      output = subject.run_command("identify", "-format", "%w", subject.path)
      expect(output).must_equal subject.width.to_s
    end
  end

  describe "#data" do
    describe "when the data return is not an array" do
      let(:subject) { described_class.new(image_path(:jpg)) }

      it "returns image JSON data" do
        expect(subject.data["format"]).must_equal "JPEG"
        expect(subject.data["colorspace"]).must_equal "sRGB"
      end
    end

    describe "when the data return is an array (ex png)" do
      let(:subject) { described_class.new(image_path(:png)) }

      it "returns image JSON data" do
        expect(subject.data["format"]).must_equal "PNG"
        expect(subject.data["colorspace"]).must_equal "sRGB"
      end
    end
  end
end
