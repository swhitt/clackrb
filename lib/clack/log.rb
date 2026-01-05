module Clack
  module Log
    class << self
      def message(msg = "", symbol: nil, output: $stdout)
        symbol ||= Colors.gray(Symbols::S_BAR)
        lines = msg.to_s.lines

        if lines.empty?
          output.puts symbol
        else
          lines.each_with_index do |line, idx|
            prefix = (idx == 0) ? symbol : Colors.gray(Symbols::S_BAR)
            output.puts "#{prefix}  #{line.chomp}"
          end
        end
      end

      def info(msg, output: $stdout)
        message(msg, symbol: Colors.blue(Symbols::S_INFO), output:)
      end

      def success(msg, output: $stdout)
        message(msg, symbol: Colors.green(Symbols::S_SUCCESS), output:)
      end

      def step(msg, output: $stdout)
        message(msg, symbol: Colors.green(Symbols::S_STEP_SUBMIT), output:)
      end

      def warn(msg, output: $stdout)
        message(msg, symbol: Colors.yellow(Symbols::S_WARN), output:)
      end
      alias_method :warning, :warn

      def error(msg, output: $stdout)
        message(msg, symbol: Colors.red(Symbols::S_ERROR), output:)
      end
    end
  end
end
