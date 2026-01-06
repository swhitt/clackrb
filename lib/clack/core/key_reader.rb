# frozen_string_literal: true

require "io/console"

module Clack
  module Core
    module KeyReader
      class << self
        def read
          IO.console.raw do |io|
            char = io.getc
            return char unless char == "\e"

            # Check for escape sequence
            return char unless IO.select([io], nil, nil, 0.05)

            seq = io.getc.to_s
            return "\e#{seq}" unless seq == "["

            # Read CSI sequence
            seq += io.getc.to_s while IO.select([io], nil, nil, 0.01)
            "\e[#{seq[1..]}"
          end
        end
      end
    end
  end
end
