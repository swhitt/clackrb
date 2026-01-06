module Clack
  module Note
    class << self
      def render(message = "", title: nil, output: $stdout)
        lines = message.to_s.lines.map(&:chomp)
        width = calculate_width(lines, title)

        output.puts Colors.gray(Symbols::S_BAR).to_s
        output.puts build_top_border(title, width)

        lines.each do |line|
          padded = line.ljust(width)
          output.puts "#{Colors.gray(Symbols::S_BAR)}  #{Colors.dim(padded)}  #{Colors.gray(Symbols::S_BAR)}"
        end

        output.puts build_bottom_border(width)
        output.puts Colors.gray(Symbols::S_BAR)
      end

      private

      def calculate_width(lines, title)
        max_line = lines.map(&:length).max || 0
        title_len = title ? title.length + 2 : 0
        [max_line, title_len, 20].max
      end

      def build_top_border(title, width)
        if title
          left = "#{Symbols::S_CONNECT_LEFT}#{Symbols::S_BAR_H}"
          right_len = width - title.length + 1
          right = "#{Symbols::S_BAR_H * right_len}#{Symbols::S_CORNER_TOP_RIGHT}"
          "#{Colors.gray(left)} #{Colors.green(title)} #{Colors.gray(right)}"
        else
          border = Symbols::S_BAR_H * (width + 4)
          "#{Colors.gray(Symbols::S_CORNER_TOP_LEFT)}#{Colors.gray(border)}#{Colors.gray(Symbols::S_CORNER_TOP_RIGHT)}"
        end
      end

      def build_bottom_border(width)
        border = Symbols::S_BAR_H * (width + 4)
        "#{Colors.gray(Symbols::S_CORNER_BOTTOM_LEFT)}#{Colors.gray(border)}#{Colors.gray(Symbols::S_CORNER_BOTTOM_RIGHT)}"
      end
    end
  end
end
