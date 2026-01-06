# frozen_string_literal: true

module Clack
  module Core
    module Settings
      # Navigation and control actions
      ACTIONS = %i[up down left right space enter cancel].freeze

      # Key code constants
      KEY_BACKSPACE = "\b"        # ASCII 8: Backspace
      KEY_DELETE = "\u007F"       # ASCII 127: Delete (often sent by backspace key)
      KEY_CTRL_C = "\u0003"       # ASCII 3: Ctrl+C (interrupt)
      KEY_ESCAPE = "\e"           # ASCII 27: Escape
      KEY_ENTER = "\r"            # ASCII 13: Carriage return
      KEY_NEWLINE = "\n"          # ASCII 10: Line feed
      KEY_SPACE = " "             # ASCII 32: Space

      # First printable ASCII character (space)
      PRINTABLE_CHAR_MIN = 32

      # Key to action mappings
      ALIASES = {
        "k" => :up,
        "j" => :down,
        "h" => :left,
        "l" => :right,
        "\e[A" => :up,
        "\e[B" => :down,
        "\e[C" => :right,
        "\e[D" => :left,
        KEY_ENTER => :enter,
        KEY_NEWLINE => :enter,
        KEY_SPACE => :space,
        KEY_ESCAPE => :cancel,
        KEY_CTRL_C => :cancel
      }.freeze

      class << self
        def action?(key)
          ALIASES[key] if ACTIONS.include?(ALIASES[key])
        end

        # Check if a key is a printable character
        def printable?(key)
          key && key.length == 1 && key.ord >= PRINTABLE_CHAR_MIN
        end

        # Check if a key is a backspace/delete
        def backspace?(key)
          key == KEY_BACKSPACE || key == KEY_DELETE
        end
      end
    end
  end
end
