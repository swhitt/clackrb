# frozen_string_literal: true

module Clack
  module Core
    # Shared functionality for text input prompts (Text, Autocomplete, Path).
    # Handles cursor display, placeholder rendering, and text manipulation.
    module TextInputHelper
      # Display the input field with cursor or placeholder.
      #
      # @return [String] Formatted input display
      def input_display
        return placeholder_display if @value.empty?

        value_with_cursor
      end

      # Display placeholder with cursor on first character.
      # Override @placeholder in including class to customize.
      #
      # @return [String] Formatted placeholder
      def placeholder_display
        text = current_placeholder
        return cursor_block if text.nil? || text.empty?

        format_placeholder_with_cursor(text)
      end

      def current_placeholder
        defined?(@placeholder) ? @placeholder : nil
      end

      def format_placeholder_with_cursor(text)
        chars = text.grapheme_clusters
        first = chars.first || ""
        rest = chars[1..].join
        "#{Colors.inverse(first)}#{Colors.dim(rest)}"
      end

      # Display value with inverse cursor at current position.
      # Uses grapheme clusters for proper Unicode handling (e.g., emoji).
      #
      # @return [String] Value with cursor
      def value_with_cursor
        chars = @value.grapheme_clusters
        return "#{@value}#{cursor_block}" if @cursor >= chars.length

        before = chars[0...@cursor].join
        current = Colors.inverse(chars[@cursor])
        after = chars[(@cursor + 1)..].join
        "#{before}#{current}#{after}"
      end

      # Handle text input key (backspace or printable character).
      # Requires @value and @cursor instance variables.
      # Uses grapheme clusters for proper Unicode handling.
      #
      # @param key [String] The key pressed
      # @return [Boolean] true if input was handled
      def handle_text_input(key)
        return false unless Core::Settings.printable?(key)

        chars = @value.grapheme_clusters

        if Core::Settings.backspace?(key)
          return false if @cursor.zero?

          chars.delete_at(@cursor - 1)
          @value = chars.join
          @cursor -= 1
        else
          chars.insert(@cursor, key)
          @value = chars.join
          @cursor += 1
        end

        true
      end
    end
  end
end
