# frozen_string_literal: true

module Clack
  module Core
    # ANSI escape sequences for cursor control.
    # See: https://en.wikipedia.org/wiki/ANSI_escape_code
    module Cursor
      class << self
        # Visibility
        # DECTCEM: Hide cursor
        def hide = "\e[?25l"
        # DECTCEM: Show cursor
        def show = "\e[?25h"

        # Movement (CSI sequences)
        # CUU: Cursor Up
        def up(n = 1) = "\e[#{n}A"
        # CUD: Cursor Down
        def down(n = 1) = "\e[#{n}B"
        # CUF: Cursor Forward
        def forward(n = 1) = "\e[#{n}C"
        # CUB: Cursor Back
        def back(n = 1) = "\e[#{n}D"

        # Absolute positioning
        # CUP: Cursor Position
        def to(x, y) = "\e[#{y};#{x}H"
        # CHA: Cursor Horizontal Absolute
        def column(n) = "\e[#{n}G"
        # CUP: Home position (1,1)
        def home = "\e[H"

        # Save/restore
        # DECSC: Save Cursor Position
        def save = "\e7"
        # DECRC: Restore Cursor Position
        def restore = "\e8"

        # Erasing
        # EL: Erase entire line
        def clear_line = "\e[2K"
        # EL: Erase to end of line
        def clear_to_end = "\e[K"
        # ED: Erase below cursor
        def clear_down = "\e[J"
        # ED: Erase entire screen
        def clear_screen = "\e[2J"
      end
    end
  end
end
