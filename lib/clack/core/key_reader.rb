# frozen_string_literal: true

require "io/console"

module Clack
  module Core
    module KeyReader
      class << self
        def read
          console = IO.console
          raise IOError, "No console available (not a TTY?)" unless console

          console.raw do |io|
            char = io.getc
            return char if char.nil? # EOF
            return char unless char == "\e"

            # Check for escape sequence
            return char unless IO.select([io], nil, nil, 0.05)

            seq = io.getc.to_s
            return "\e#{seq}" unless seq == "["

            # Read CSI sequence
            seq += io.getc.to_s while IO.select([io], nil, nil, 0.01)
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
