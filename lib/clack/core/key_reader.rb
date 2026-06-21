# frozen_string_literal: true

require "io/console"

module Clack
  module Core
    # Reads single keystrokes from the terminal in raw mode.
    # Handles escape sequences for arrow keys and other special keys.
    #
    # The Escape detection window is tunable via the +CLACK_ESCAPE_TIMEOUT+
    # env var (see {Environment.escape_timeout}) for high-latency links.
    module KeyReader
      class << self
        # Read a single keystroke in raw mode.
        # When input is an IO backed by a console, uses raw mode.
        # When input is a StringIO or test double, reads directly.
        #
        # @param input [IO, nil] input stream (defaults to IO.console)
        # @return [String, nil] the key code, or nil on EOF
        def read(input = nil)
          io = input || IO.console
          raise IOError, "No console available (not a TTY?)" unless io

          # StringIO / test doubles don't support raw mode
          return read_from(io) unless io.respond_to?(:raw)

          io.raw { |raw_io| read_from(raw_io) }
        rescue Errno::EIO, Errno::EBADF, IOError
          # Terminal disconnected or closed - treat as cancel
          "\u0003" # Ctrl+C
        end

        private

        def read_from(io)
          char = io.getc
          return char if char.nil? # EOF
          return char unless char == "\e"

          escape_timeout = Environment.escape_timeout
          # Subsequent bytes in a sequence normally arrive almost instantly, so
          # the inter-byte wait stays much shorter, but it scales with the
          # escape timeout so high-latency links still assemble full sequences.
          sequence_timeout = escape_timeout / 5.0

          # Check for escape sequence - wait briefly for follow-up
          return char unless io.respond_to?(:wait_readable) && io.wait_readable(escape_timeout)

          seq = io.getc.to_s
          return "\e#{seq}" unless seq == "["

          # Read CSI sequence until no more characters arrive
          while io.respond_to?(:wait_readable) && io.wait_readable(sequence_timeout)
            seq += io.getc.to_s
          end
          "\e[#{seq[1..]}"
        end
      end
    end
  end
end
