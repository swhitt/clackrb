# frozen_string_literal: true

module Clack
  # Utility functions for text manipulation and formatting
  module Utils
    class << self
      # Strip ANSI escape sequences from text
      # @param text [String] Text with ANSI codes
      # @return [String] Text without ANSI codes
      def strip_ansi(text)
        text.to_s.gsub(/\e\[[0-9;]*[a-zA-Z]/, "")
      end

      # Get visible length (display width in columns) of text after stripping ANSI.
      # Uses display_width to correctly measure CJK, emoji, combining chars.
      # @param text [String]
      # @return [Integer] display columns
      def visible_length(text)
        display_width(strip_ansi(text))
      end

      # Calculate the terminal display width (columns) of a string.
      # ASCII and most chars: width 1. CJK ideographs, fullwidth forms, common emoji: width 2.
      # Zero-width joiners, combining marks, variation selectors: width 0.
      # @param string [String]
      # @return [Integer]
      def display_width(string)
        str = string.to_s
        return 0 if str.empty?

        width = 0
        str.grapheme_clusters.each do |cluster|
          width += grapheme_width(cluster)
        end
        width
      end

      # Wrap text to a specified width, preserving ANSI codes
      # @param text [String] Text to wrap
      # @param width [Integer] Maximum line width
      # @return [String] Wrapped text
      def wrap(text, width)
        return text if width <= 0

        lines = []
        text.to_s.each_line do |line|
          lines.concat(wrap_line(line.chomp, width))
        end
        lines.join("\n")
      end

      # Wrap text with a prefix on each line
      # @param text [String] Text to wrap
      # @param prefix [String] Prefix for each line (e.g., "│  ")
      # @param width [Integer] Total width including prefix
      # @return [String] Wrapped and prefixed text
      def wrap_with_prefix(text, prefix, width)
        prefix_len = visible_length(prefix)
        content_width = width - prefix_len
        return text if content_width <= 0

        wrapped = wrap(text, content_width)
        wrapped.lines.map { |line| "#{prefix}#{line.chomp}" }.join("\n")
      end

      # Truncate text to width with ellipsis
      # @param text [String] Text to truncate
      # @param width [Integer] Maximum width
      # @param ellipsis [String] Ellipsis string (default: "...")
      # @return [String] Truncated text
      def truncate(text, width, ellipsis: "...")
        return text if visible_length(text) <= width

        target = width - visible_length(ellipsis)
        return ellipsis if target <= 0

        # Handle ANSI codes: we need to truncate visible chars while preserving codes
        truncate_visible(text, target) + ellipsis
      end

      private

      def wrap_line(line, width)
        return [line] if visible_length(line) <= width

        words = line.split(/(\s+)/)
        lines = []
        current = ""
        current_len = 0

        words.each do |word|
          word_len = visible_length(word)

          if current_len + word_len <= width
            current += word
            current_len += word_len
          elsif word_len > width
            # Word itself is too long, need to break it
            unless current.empty?
              lines << current.rstrip
              current = ""
              current_len = 0
            end
            lines.concat(break_long_word(word, width))
          else
            lines << current.rstrip unless current.empty?
            current = word.lstrip
            current_len = visible_length(current)
          end
        end

        lines << current.rstrip unless current.empty?
        lines
      end

      def break_long_word(word, width)
        lines = []
        clusters = strip_ansi(word).grapheme_clusters

        chunk = +""
        chunk_width = 0
        clusters.each do |gc|
          gw = grapheme_width(gc)
          if chunk_width + gw > width && !chunk.empty?
            lines << chunk
            chunk = +""
            chunk_width = 0
          end
          chunk << gc
          chunk_width += gw
          # Force include first grapheme even if its width exceeds limit
          if gw > width && chunk_width == gw
            lines << chunk
            chunk = +""
            chunk_width = 0
          end
        end
        lines << chunk unless chunk.empty?

        lines
      end

      def truncate_visible(text, target_len)
        result = +""
        visible_width = 0
        position = 0
        ansi_re = /\A\e\[[0-9;]*[a-zA-Z]/

        while position < text.length && visible_width < target_len
          if text[position] == "\e" && (match = text[position..].match(ansi_re))
            result << match[0]
            position += match[0].length
          else
            # Extract the grapheme cluster starting at this position
            gc = text[position..].grapheme_clusters.first
            break unless gc

            gw = grapheme_width(gc)
            break if visible_width + gw > target_len
            result << gc
            visible_width += gw
            position += gc.length
          end
        end

        result << "\e[0m" if result.include?("\e[") && !result.end_with?("\e[0m")
        result
      end

      # Width of a grapheme cluster: the max char_width among its codepoints.
      # Handles ZWJ emoji sequences, combining marks, and flag sequences correctly.
      def grapheme_width(cluster)
        max_w = 0
        cluster.each_char do |char|
          w = char_width(char)
          max_w = w if w > max_w
        end
        max_w
      end

      def char_width(char)
        code = char.ord
        return 0 if zero_width_code?(code)
        return 2 if wide_char_code?(code)
        1
      end

      def zero_width_code?(code)
        return true if (0x0300..0x036F).cover?(code)
        return true if (0x1AB0..0x1AFF).cover?(code)
        return true if (0x20D0..0x20FF).cover?(code)
        return true if [0x200B, 0x200C, 0x200D, 0xFEFF].include?(code)
        return true if (0xFE00..0xFE0F).cover?(code)
        false
      end

      def wide_char_code?(code)
        # CJK Unified + extensions + compatibility
        return true if (0x4E00..0x9FFF).cover?(code)
        return true if (0x3400..0x4DBF).cover?(code)
        return true if (0xF900..0xFAFF).cover?(code)
        # Korean Hangul syllables
        return true if (0xAC00..0xD7AF).cover?(code)
        # Japanese kana
        return true if (0x3040..0x309F).cover?(code)
        return true if (0x30A0..0x30FF).cover?(code)
        # Fullwidth and wide punctuation
        return true if (0x3000..0x303F).cover?(code)
        return true if (0xFF01..0xFF5E).cover?(code)
        return true if (0xFFE0..0xFFE6).cover?(code)
        # Common emoji / symbols blocks that render as wide
        return true if (0x1F000..0x1F9FF).cover?(code)
        return true if (0x2600..0x26FF).cover?(code)
        return true if (0x2700..0x27BF).cover?(code)
        false
      end
    end
  end
end
