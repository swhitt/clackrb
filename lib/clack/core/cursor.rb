module Clack
  module Core
    module Cursor
      class << self
        def hide = "\e[?25l"
        def show = "\e[?25h"

        def up(n = 1) = "\e[#{n}A"
        def down(n = 1) = "\e[#{n}B"
        def forward(n = 1) = "\e[#{n}C"
        def back(n = 1) = "\e[#{n}D"

        def move(x, y)
          result = ""
          result += ((x > 0) ? forward(x) : back(-x)) if x != 0
          result += ((y > 0) ? down(y) : up(-y)) if y != 0
          result
        end

        def to(x, y) = "\e[#{y};#{x}H"
        def column(n) = "\e[#{n}G"
        def home = "\e[H"

        def save = "\e7"
        def restore = "\e8"

        def clear_line = "\e[2K"
        def clear_to_end = "\e[K"
        def clear_down = "\e[J"
        def clear_screen = "\e[2J"
      end
    end
  end
end
