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

      # Get visible length of text (excluding ANSI codes)
      # @param text [String] Text potentially containing ANSI codes
      # @return [Integer] Visible character count
      def visible_length(text)
        strip_ansi(text).length
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

        target = width - ellipsis.length
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
        stripped = strip_ansi(word)
        position = 0

        while position < stripped.length
          lines << stripped[position, width]
          position += width
        end

        lines
      end

      def truncate_visible(text, target_len)
        result = ""
        visible_count = 0
        position = 0

        while position < text.length && visible_count < target_len
          if text[position] == "\e" && (match = text[position..].match(/\A\e\[[0-9;]*[a-zA-Z]/))
            # ANSI sequence - include it but don't count
            result += match[0]
            position += match[0].length
          else
            result += text[position]
            visible_count += 1
            position += 1
          end
        end

        # Add reset if we have unclosed ANSI codes
        result += "\e[0m" if result.include?("\e[") && !result.end_with?("\e[0m")
        result
      end
    end
  end
end
