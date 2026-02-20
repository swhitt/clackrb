# frozen_string_literal: true

module Clack
  # Core building blocks for prompt rendering and interaction.
  module Core
    # ANSI escape sequences for cursor control.
    # See: https://en.wikipedia.org/wiki/ANSI_escape_code
    module Cursor
      class << self
        # Override enabled state for testing or special cases
        attr_writer :enabled

        def enabled?
          return @enabled unless @enabled.nil?

          # Default: check if output supports ANSI escape sequences
          $stdout.tty? && ENV["TERM"] != "dumb" && !ENV["NO_COLOR"]
        end

        # Visibility
        # DECTCEM: Hide cursor
        def hide = enabled? ? "\e[?25l" : ""
        # DECTCEM: Show cursor
        def show = enabled? ? "\e[?25h" : ""

        # Movement (CSI sequences)
        # CUU: Cursor Up
        def up(n = 1) = enabled? ? "\e[#{n}A" : ""
        # CUD: Cursor Down
        def down(n = 1) = enabled? ? "\e[#{n}B" : ""
        # CUF: Cursor Forward
        def forward(n = 1) = enabled? ? "\e[#{n}C" : ""
        # CUB: Cursor Back
        def back(n = 1) = enabled? ? "\e[#{n}D" : ""

        # Absolute positioning
        # CUP: Cursor Position
        def to(x, y) = enabled? ? "\e[#{y};#{x}H" : ""
        # CHA: Cursor Horizontal Absolute
        def column(n) = enabled? ? "\e[#{n}G" : ""
        # CUP: Home position (1,1)
        def home = enabled? ? "\e[H" : ""

        # Save/restore
        # DECSC: Save Cursor Position
        def save = enabled? ? "\e7" : ""
        # DECRC: Restore Cursor Position
        def restore = enabled? ? "\e8" : ""

        # Erasing
        # EL: Erase entire line
        def clear_line = enabled? ? "\e[2K" : ""
        # EL: Erase to end of line
        def clear_to_end = enabled? ? "\e[K" : ""
        # ED: Erase below cursor
        def clear_down = enabled? ? "\e[J" : ""
        # ED: Erase entire screen
        def clear_screen = enabled? ? "\e[2J" : ""
      end
    end
  end
end
