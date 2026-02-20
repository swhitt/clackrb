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
        # Read a single keystroke from the terminal in raw mode.
        # Handles multi-byte escape sequences (arrow keys, etc.).
        #
        # @return [String, nil] the key code, or nil on EOF
        # @raise [IOError] if no console is available
        def read
          console = IO.console
          raise IOError, "No console available (not a TTY?)" unless console

          console.raw do |io|
            char = io.getc
            return char if char.nil? # EOF
            return char unless char == "\e"

            # Check for escape sequence - wait briefly for follow-up
            return char unless IO.select([io], nil, nil, ESCAPE_TIMEOUT)

            seq = io.getc.to_s
            return "\e#{seq}" unless seq == "["

            # Read CSI sequence until no more characters arrive
            seq += io.getc.to_s while IO.select([io], nil, nil, SEQUENCE_TIMEOUT)
            "\e[#{seq[1..]}"
          end
        rescue Errno::EIO, Errno::EBADF, IOError
          # Terminal disconnected or closed - treat as cancel
          "\u0003" # Ctrl+C
        end
      end
    end
  end
end
