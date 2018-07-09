module CryMagick
  class Tool
    CREATION_OPERATORS = %w(xc canvas logo rose gradient radial-gradient plasma pattern label caption text pango)

    def self.build(name : String) : String
      instance = new(name)
      yield instance
      instance.call
    end

    getter name : String, args
    @whiny : Bool

    def initialize(@name)
      @args = [] of String
      @whiny = Configuration.whiny
    end

    def initialize(@name, options : Hash(Symbol, Bool) = {} of Symbol => Bool)
      @args = [] of String
      @whiny = options.has_key?(:whiny) ? options[:whiny] : Configuration.whiny
    end

    def call : String
      shell = Shell.new
      stdout, status, stderr = shell.run(command, {:whiny => @whiny})
      stdout.to_s.strip
    end

    def call(&block)
      shell = Shell.new
      stdout, stderr, status = shell.run(command, {:whiny => @whiny})
      yield stdout, stderr, status
      stdout.to_s.strip
    end

    def command
      arr = [] of String
      arr.concat(executable)
      arr.concat(args)
      arr
    end

    def executable
      exe = [name]
      exe.unshift File.join(Configuration.cli_path, exe.shift) unless Configuration.cli_path.empty?
      exe
    end

    def <<(arg)
      args << arg.to_s
      self
    end

    def send(name, *opts)
      args << "-#{name}"
      merge!(opts)
    end

    def merge!(new_args)
      new_args.each { |arg| self << arg }
      self
    end

    def +(*values)
      args[-1] = args[-1].sub(/^-/, "+")
      merge!(values)
      self
    end

    def stack
      self << "\\("
      yield self
      self << "\\)"
    end

    def stdin
      self << "-"
    end

    def stdout
      self << "-"
    end

    {% for operator in CREATION_OPERATORS %}
      def {{operator.tr("-", "_").id}}(value)
        self << "{{operator.id}}:#{value.to_s}"
        self
      end

      def {{operator.tr("-", "_").id}}
        self << "{{operator.id}}:"
        self
      end
    {% end %}

    def clone(*args)
      send("clone", *args)
    end

    # Currently notification about dynamically generated methods will be printed out
    # to stdout during compilation
    macro method_missing(call)
      {% p "Dynamically generates method #{@type}##{call.id}".id %}
      def {{call.name.id}}(*args)
        send({{call.name.tr("_", "-").id.stringify}}, *args)
      end
    end
  end
end

require "./tool/*"
