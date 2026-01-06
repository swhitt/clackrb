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
        "#{Colors.inverse(text[0])}#{Colors.dim(text[1..])}"
      end

      # Display value with inverse cursor at current position.
      #
      # @return [String] Value with cursor
      def value_with_cursor
        return "#{@value}#{cursor_block}" if @cursor >= @value.length

        before = @value[0...@cursor]
        current = Colors.inverse(@value[@cursor])
        after = @value[(@cursor + 1)..]
        "#{before}#{current}#{after}"
      end

      # Handle text input key (backspace or printable character).
      # Requires @value and @cursor instance variables.
      #
      # @param key [String] The key pressed
      # @return [Boolean] true if input was handled
      def handle_text_input(key)
        return false unless Core::Settings.printable?(key)

        if Core::Settings.backspace?(key)
          return false if @cursor.zero?

          @value = @value[0...(@cursor - 1)] + @value[@cursor..]
          @cursor -= 1
        else
          @value = @value[0...@cursor] + key + @value[@cursor..]
          @cursor += 1
        end

        true
      end
    end
  end
end
