# frozen_string_literal: true

require "io/console"

module Clack
  module Core
    # Reads single keystrokes from the terminal in raw mode.
    # Handles escape sequences for arrow keys and other special keys.
    module KeyReader
      # Timeout for detecting if Escape is part of a sequence (50ms).
      # If no follow-up character arrives, treat Escape as a standalone key.
      ESCAPE_TIMEOUT = 0.05

      # Timeout for reading additional characters in a CSI sequence (10ms).
      # Short because subsequent bytes in a sequence arrive almost instantly.
      SEQUENCE_TIMEOUT = 0.01

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

          # Check for escape sequence - wait briefly for follow-up
          return char unless io.respond_to?(:wait_readable) && io.wait_readable(ESCAPE_TIMEOUT)

          seq = io.getc.to_s
          return "\e#{seq}" unless seq == "["

          # Read CSI sequence until no more characters arrive
          while io.respond_to?(:wait_readable) && io.wait_readable(SEQUENCE_TIMEOUT)
            seq += io.getc.to_s
          end
          "\e[#{seq[1..]}"
        end
      end
    end
  end
end
