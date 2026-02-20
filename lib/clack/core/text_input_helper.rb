# frozen_string_literal: true

module Clack
  module Core
    # Shared functionality for text input prompts (Text, Autocomplete, Path).
    # Handles cursor display, placeholder rendering, and text manipulation.
    #
    # By default operates on +@value+ and +@cursor+. Override
    # +text_value+ and +text_value=+ in your class to use a different
    # backing store (e.g. +@search_text+ in AutocompleteMultiselect).
    module TextInputHelper
      # Display the input field with cursor or placeholder.
      #
      # @return [String] Formatted input display
      def input_display
        return placeholder_display if text_value.empty?

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

      # @return [String, nil] the placeholder text, or nil if none set
      def current_placeholder
        defined?(@placeholder) ? @placeholder : nil
      end

      # Render placeholder text with an inverse cursor on the first character.
      # @param text [String] placeholder text to format
      # @return [String] formatted placeholder with cursor highlight
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
        val = text_value
        chars = val.grapheme_clusters
        return "#{val}#{cursor_block}" if @cursor >= chars.length

        before = chars[0...@cursor].join
        current = Colors.inverse(chars[@cursor])
        after = chars[(@cursor + 1)..].join
        "#{before}#{current}#{after}"
      end

      # Handle text input key (backspace/delete or printable character).
      # Uses grapheme clusters for proper Unicode handling.
      #
      # @param key [String] The key pressed
      # @return [Boolean] true if input was handled
      def handle_text_input(key)
        return handle_backspace if Core::Settings.backspace?(key)
        return false unless Core::Settings.printable?(key)

        chars = text_value.grapheme_clusters
        chars.insert(@cursor, key)
        self.text_value = chars.join
        @cursor += 1
        true
      end

      # The text value being edited. Override to use a different backing store.
      # @return [String]
      def text_value
        @value
      end

      # Set the text value. Override to use a different backing store.
      # @param val [String]
      def text_value=(val)
        @value = val
      end

      private

      def handle_backspace
        return false if @cursor.zero?

        chars = text_value.grapheme_clusters
        chars.delete_at(@cursor - 1)
        self.text_value = chars.join
        @cursor -= 1
        true
      end
    end
  end
end
