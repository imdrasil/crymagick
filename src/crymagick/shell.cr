module CryMagick
  class Shell
    def run(command, options : Hash(Symbol, Bool | String) = {} of Symbol => Bool | String)
      whiny = options.has_key?(:whiny) ? options[:whiny] : Configuration.whiny
      stdout, stderr, status = execute(command)
      if status != 0 && whiny
        raise Error.new("`#{command.join(" ")}` failed with error(#{status}):\n#{stderr.to_s}\noutput:\n#{stdout}")
      end
      {stdout, stderr, status}
    end

    def execute(command : Array(String))
      output = IO::Memory.new
      error = IO::Memory.new
      command[1..-1].each_with_index do |e, i|
        j = i + 1
        command[j] = "'#{e}'" if e.includes?(' ')
      end
      res = Process.run(command.join(" "), shell: true, output: output, error: error)
      {output, error, res.exit_status}
    end
  end
end
