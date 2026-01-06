module Clack
  module Note
    class << self
      def render(message = "", title: nil, output: $stdout)
        lines = message.to_s.lines.map(&:chomp)
        # Add empty lines at start and end like original
        lines = ["", *lines, ""]
        title_len = title&.length || 0
        width = calculate_width(lines, title_len)

        output.puts Colors.gray(Symbols::S_BAR)
        output.puts build_top_border(title, title_len, width)

        lines.each do |line|
          padded = line.ljust(width)
          output.puts "#{Colors.gray(Symbols::S_BAR)}  #{Colors.dim(padded)}#{Colors.gray(Symbols::S_BAR)}"
        end

        output.puts build_bottom_border(width)
      end

      private

      def calculate_width(lines, title_len)
        max_line = lines.map(&:length).max || 0
        [max_line, title_len].max + 2
      end

      def build_top_border(title, title_len, width)
        if title
          # Format: ◇  title ───────╮
          right_len = [width - title_len - 1, 1].max
          right = "#{Symbols::S_BAR_H * right_len}#{Symbols::S_CORNER_TOP_RIGHT}"
          "#{Colors.green(Symbols::S_STEP_SUBMIT)}  #{title} #{Colors.gray(right)}"
        else
          border = Symbols::S_BAR_H * (width + 2)
          "#{Colors.gray(Symbols::S_CORNER_TOP_LEFT)}#{Colors.gray(border)}#{Colors.gray(Symbols::S_CORNER_TOP_RIGHT)}"
        end
      end

      def build_bottom_border(width)
        border = Symbols::S_BAR_H * (width + 2)
        "#{Colors.gray(Symbols::S_CONNECT_LEFT)}#{Colors.gray(border)}#{Colors.gray(Symbols::S_CORNER_BOTTOM_RIGHT)}"
      end
    end
  end
end
