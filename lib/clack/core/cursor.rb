# frozen_string_literal: true

module Clack
  module Core
    # ANSI escape sequences for cursor control.
    # See: https://en.wikipedia.org/wiki/ANSI_escape_code
    module Cursor
      class << self
        # Visibility
        def hide = "\e[?25l"  # DECTCEM: Hide cursor
        def show = "\e[?25h"  # DECTCEM: Show cursor

        # Movement (CSI sequences)
        def up(n = 1) = "\e[#{n}A"      # CUU: Cursor Up
        def down(n = 1) = "\e[#{n}B"    # CUD: Cursor Down
        def forward(n = 1) = "\e[#{n}C" # CUF: Cursor Forward
        def back(n = 1) = "\e[#{n}D"    # CUB: Cursor Back

        # Relative movement
        def move(x, y)
          result = []
          result << (x.positive? ? forward(x) : back(-x)) unless x.zero?
          result << (y.positive? ? down(y) : up(-y)) unless y.zero?
          result.join
        end

        # Absolute positioning
        def to(x, y) = "\e[#{y};#{x}H" # CUP: Cursor Position
        def column(n) = "\e[#{n}G"     # CHA: Cursor Horizontal Absolute
        def home = "\e[H"              # CUP: Home position (1,1)

        # Save/restore
        def save = "\e7"    # DECSC: Save Cursor Position
        def restore = "\e8" # DECRC: Restore Cursor Position

        # Erasing
        def clear_line = "\e[2K"    # EL: Erase entire line
        def clear_to_end = "\e[K"   # EL: Erase to end of line
        def clear_down = "\e[J"     # ED: Erase below cursor
        def clear_screen = "\e[2J"  # ED: Erase entire screen
      end
    end
  end
end
