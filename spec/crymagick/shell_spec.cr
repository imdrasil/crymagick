require "../spec_helper"

describe Shell do
  let(:subject) { CryMagick::Shell.new }

  describe "#run" do
    it "returns stdout, stderr and status" do
      output = subject.run(["echo", %("asd")])
      expect([output[0].to_s, output[1].to_s, output[2]]).must_equal ["asd\n", "", 0]
    end

    it "raises an error when executable wasn't found" do
      assert_raises(CryMagick::Error) do
        subject.run(%w[foo])
      end
    end

    it "raises errors only in whiny mode" do
      subject.run(%w[foo], {:whiny => false})
    end
  end

  describe "#execute" do
    it "executes the command in the shell" do
      stdout, stderr, status = subject.execute(["identify", "#{image_path(:gif)}"])

      stdout = stdout.to_s
      stderr = stderr.to_s
      expect(stdout).must_match("GIF")
      expect(stderr).must_equal ""
      expect(status).must_equal 0

      stdout, stderr, status = subject.execute(%w[identify foo])
      stdout = stdout.to_s
      stderr = stderr.to_s

      expect(stdout).must_equal ""
      expect(stderr).must_match(/unable to open image [`']foo'/)
      expect(status).must_equal 256
    end

    it "handles larger output" do
      # Timeout.timeout(1) do
      stdout = subject.execute(["convert", "#{image_path(:gif)}", "-"])[0]
      expect(stdout.to_s).must_match("GIF")
      # end
    end

    it "returns an appropriate response when command wasn't found" do
      code = subject.execute(%w[unexisting command])[2]
      expect(code).must_equal 32512
    end

    # it "logs the command and execution time in debug mode" do
    #  MiniMagick.logger = Logger.new(stream = StringIO.new)
    #  MiniMagick.logger.level = Logger::DEBUG
    #  subject.execute(%W[identify #{image_path(:gif)}])
    #  stream.rewind
    #  expect(stream.read).to match /\[\d+.\d+s\] identify #{image_path(:gif)}/
    # end

    # it "terminate long running commands if MiniMagick.timeout is set" do
    #  MiniMagick.timeout = 0.1
    #  expect { subject.execute(%w[sleep 0.2]) }.to raise_error(Timeout::Error)
    #  MiniMagick.timeout = nil
    # end

    it "doesn't break on spaces" do
      stdout = subject.execute(["identify", "-format", "%w %h", image_path])[0]
      expect(stdout.to_s).must_match(/\d+ \d+/)
    end
  end
end
