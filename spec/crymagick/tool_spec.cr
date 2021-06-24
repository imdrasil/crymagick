require "../spec_helper"

describe CryMagick::Tool do
  @subject : CryMagick::Tool::Identify?
  let(:subject) { CryMagick::Tool::Identify.new }
  let(:described_class) { CryMagick::Tool }

  describe "#call" do
    it "calls the shell to run the command" do
      subject << image_path(:gif)
      output = subject.call
      expect(output).must_match("GIF")
    end

    it "strips the output" do
      subject << image_path
      output = subject.call
      expect(output.ends_with?("\n")).must_equal(false)
    end

    # it "accepts stdin" do
    # subject << "-"
    # output = subject.call({"stdin" => File.read(image_path)})
    # expect(output).must_match(/JPEG/)
    # end
  end

  describe ".new" do
    it "accepts a block, and immediately executes the command" do
      output = CryMagick::Tool.build("identify") do |builder|
        builder << image_path(:gif)
      end
      expect(output).must_match("GIF")
    end
  end

  describe "#command" do
    it "includes the executable and the arguments" do
      subject.list("Command")
      expect(subject.command).must_equal(%w(identify -list Command))
    end
  end

  describe "#executable" do
    # it "prepends 'gm' to the command list when using GraphicsMagick" do
    # CryMagick::Configuration.cli = :graphicsmagick
    # allow(CryMagick).to receive(:cli).and_return(:graphicsmagick)
    # expect(subject.executable).must_equal %W(gm identify)
    # end

    it "respects #cli_path" do
      begin
        CryMagick::Configuration.cli_path = "path/to/cli"
        expect(subject.executable).must_equal %w(path/to/cli/identify)
      ensure
        CryMagick::Configuration.cli_path = ""
      end
    end
  end
  # #<<
  describe "#append" do
    it "adds argument to the args list" do
      subject << "foo" << "bar" << 123
      expect(subject.args).must_equal %w(foo bar 123)
    end
  end

  describe "#merge!" do
    it "adds arguments to the args list" do
      subject << "pre-existing"
      subject.merge! ["foo", 123]
      expect(subject.args).must_equal %w(pre-existing foo 123)
    end
  end

  # #+
  describe "#plus" do
    it "switches the last option to + form" do
      subject.help
      subject.help.+
      subject.debug.+ "foo"
      subject.debug.+ 8, "bar"
      expect(subject.args).must_equal %w(-help +help +debug foo +debug 8 bar)
    end
  end

  describe "#stdin" do
    it "appends the '-' pseudo-filename" do
      subject.stdin
      expect(subject.args).must_equal %w(-)
    end
  end

  describe "#stdout" do
    it "appends the '-' pseudo-filename" do
      subject.stdout
      expect(subject.args).must_equal %w(-)
    end
  end

  describe "#stack" do
    it "it surrounds added arguments with parantheses" do
      subject.stack do |stack|
        stack << "foo"
        stack << "bar"
      end
      expect(subject.args).must_equal ["\\(", "foo", "bar", "\\)"]
    end
  end

  describe "#clone" do
    it "adds an option instead of the default behaviour" do
      subject.clone
      expect(subject.args).must_equal %w(-clone)
    end

    it "accepts arguments" do
      subject.clone(0)
      expect(subject.args).must_equal %w(-clone 0)
    end

    it "is convertable to plus version" do
      subject.clone.+
      expect(subject.args).must_equal %w(+clone)
    end
  end

  describe "#method_missing" do
    it "adds CLI options" do
      subject.foo_bar("baz")
      expect(subject.args).must_equal %w(-foo-bar baz)
    end
  end

  it "defines creation operator methods" do
    subject.radial_gradient.canvas "khaki"
    expect(subject.args).must_equal %w(radial-gradient: canvas:khaki)
  end

  it "doesn't raise errors when false is passed to the constructor" do
    subject.help

    CryMagick::Tool::Identify.build({:whiny => false}, &.help)
  end
end
