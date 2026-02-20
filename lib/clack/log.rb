# frozen_string_literal: true

module Clack
  # Styled console logging with consistent formatting.
  #
  # Each method prints a message prefixed with a colored symbol. Multi-line
  # messages are automatically aligned with a continuation bar on subsequent lines.
  #
  # Accessed via +Clack.log+:
  #
  # @example
  #   Clack.log.info("Starting build...")
  #   Clack.log.success("Build completed!")
  #   Clack.log.warn("Cache is stale")
  #   Clack.log.error("Build failed")
  #
  module Log
    class << self
      # Print a message with a custom or default symbol prefix.
      #
      # This is the base method used by all other log methods. Pass +symbol:+
      # to customize the leading character (useful for extending with your own
      # log levels).
      #
      # @param msg [String] the message to display
      # @param symbol [String, nil] custom prefix symbol (default: gray bar)
      # @param output [IO] output stream (default: $stdout)
      # @return [void]
      #
      # @example Custom symbol
      #   Clack.log.message("Deploying...", symbol: "\u2708")
      def message(msg = "", symbol: nil, output: $stdout)
        symbol ||= Colors.gray(Symbols::S_BAR)
        lines = msg.to_s.lines

        if lines.empty?
          output.puts symbol
        else
          lines.each_with_index do |line, idx|
            prefix = idx.zero? ? symbol : Colors.gray(Symbols::S_BAR)
            output.puts "#{prefix}  #{line.chomp}"
          end
        end
      end

      # Print an informational message (blue symbol).
      #
      # @param msg [String] the message to display
      # @param output [IO] output stream (default: $stdout)
      # @return [void]
      def info(msg, output: $stdout)
        message(msg, symbol: Colors.blue(Symbols::S_INFO), output:)
      end

      # Print a success message (green symbol).
      #
      # @param msg [String] the message to display
      # @param output [IO] output stream (default: $stdout)
      # @return [void]
      def success(msg, output: $stdout)
        message(msg, symbol: Colors.green(Symbols::S_SUCCESS), output:)
      end

      # Print a step completion message (green submit symbol).
      #
      # @param msg [String] the message to display
      # @param output [IO] output stream (default: $stdout)
      # @return [void]
      def step(msg, output: $stdout)
        message(msg, symbol: Colors.green(Symbols::S_STEP_SUBMIT), output:)
      end

      # Print a warning message (yellow symbol).
      #
      # @param msg [String] the message to display
      # @param output [IO] output stream (default: $stdout)
      # @return [void]
      def warn(msg, output: $stdout)
        message(msg, symbol: Colors.yellow(Symbols::S_WARN), output:)
      end
      alias_method :warning, :warn

      # Print an error message (red symbol).
      #
      # @param msg [String] the message to display
      # @param output [IO] output stream (default: $stdout)
      # @return [void]
      def error(msg, output: $stdout)
        message(msg, symbol: Colors.red(Symbols::S_ERROR), output:)
      end
    end
  end
end
