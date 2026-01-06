# frozen_string_literal: true

module Clack
  # Renders a box with optional title around content
  # Supports alignment, padding, and rounded/square corners
  module Box
    class << self
      # @param message [String] Content to display in the box
      # @param title [String] Optional title for the box
      # @param content_align [:left, :center, :right] Content alignment
      # @param title_align [:left, :center, :right] Title alignment
      # @param width [Integer, :auto] Box width (auto fits to content)
      # @param title_padding [Integer] Padding around title
      # @param content_padding [Integer] Padding around content
      # @param rounded [Boolean] Use rounded corners (default: true)
      # @param format_border [Proc] Optional proc to format border characters
      # @param output [IO] Output stream
      def render(
        message = "",
        title: "",
        content_align: :left,
        title_align: :left,
        width: :auto,
        title_padding: 1,
        content_padding: 2,
        rounded: true,
        format_border: nil,
        output: $stdout
      )
        ctx = build_context(message, title, title_padding, content_padding, width, rounded, format_border)
        output.puts build_top_border(ctx[:display_title], ctx[:inner_width], title_padding, title_align, ctx[:symbols], ctx[:h_symbol])
        render_content_lines(output, ctx, content_align, content_padding)
        output.puts "#{ctx[:symbols][2]}#{ctx[:h_symbol] * ctx[:inner_width]}#{ctx[:symbols][3]}"
      end

      private

      def build_context(message, title, title_padding, content_padding, width, rounded, format_border)
        format_border ||= ->(text) { Colors.gray(text) }
        symbols = corner_symbols(rounded).map(&format_border)
        lines = message.to_s.lines.map(&:chomp)
        box_width = calculate_width(lines, title.length, title_padding, content_padding, width)
        inner_width = box_width - 2
        max_title_len = inner_width - (title_padding * 2)
        display_title = (title.length > max_title_len) ? "#{title[0, max_title_len - 3]}..." : title

        {
          symbols: symbols,
          h_symbol: format_border.call(Symbols::S_BAR_H),
          v_symbol: format_border.call(Symbols::S_BAR),
          lines: lines,
          inner_width: inner_width,
          display_title: display_title
        }
      end

      def render_content_lines(output, ctx, content_align, content_padding)
        ctx[:lines].each do |line|
          left_pad, right_pad = padding_for_line(line.length, ctx[:inner_width], content_padding, content_align)
          output.puts "#{ctx[:v_symbol]}#{" " * left_pad}#{line}#{" " * right_pad}#{ctx[:v_symbol]}"
        end
      end

      def corner_symbols(rounded)
        if rounded
          [
            Symbols::S_CORNER_TOP_LEFT,
            Symbols::S_CORNER_TOP_RIGHT,
            Symbols::S_CORNER_BOTTOM_LEFT,
            Symbols::S_CORNER_BOTTOM_RIGHT
          ]
        else
          [
            Symbols::S_BAR_START,
            Symbols::S_BAR_START_RIGHT,
            Symbols::S_BAR_END,
            Symbols::S_BAR_END_RIGHT
          ]
        end
      end

      def calculate_width(lines, title_len, title_padding, content_padding, width)
        return width + 2 if width.is_a?(Integer) # Add 2 for borders

        # Auto width: fit to content
        max_line = lines.map(&:length).max || 0
        title_with_padding = title_len + (title_padding * 2)
        content_with_padding = max_line + (content_padding * 2)

        [title_with_padding, content_with_padding].max + 2
      end

      def build_top_border(title, inner_width, title_padding, title_align, symbols, h_symbol)
        if title.empty?
          "#{symbols[0]}#{h_symbol * inner_width}#{symbols[1]}"
        else
          left_pad, right_pad = padding_for_line(title.length, inner_width, title_padding, title_align)
          "#{symbols[0]}#{h_symbol * left_pad}#{title}#{h_symbol * right_pad}#{symbols[1]}"
        end
      end

      def padding_for_line(line_length, inner_width, padding, align)
        case align
        when :center
          left = (inner_width - line_length) / 2
          right = inner_width - left - line_length
          [left, right]
        when :right
          left = inner_width - line_length - padding
          right = padding
          [[left, 0].max, right]
        else # :left
          left = padding
          right = inner_width - left - line_length
          [left, [right, 0].max]
        end
      end
    end
  end
end
