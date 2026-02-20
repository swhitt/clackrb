# frozen_string_literal: true

module Clack
  module Prompts
    # Password input prompt with masked display.
    #
    # Displays a mask character for each input character, hiding the actual
    # password. Supports backspace but not cursor movement (for security).
    #
    # @example Basic usage
    #   secret = Clack.password(message: "Enter your API key")
    #
    # @example With custom mask
    #   secret = Clack.password(message: "Password", mask: "*")
    #
    class Password < Core::Prompt
      # @param message [String] the prompt message
      # @param mask [String, nil] character to display (default: "▪")
      # @option opts [Proc, nil] :validate validation proc returning error string or nil
      # @option opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, mask: nil, **opts)
        super(message:, **opts)
        @mask = mask || Symbols::S_PASSWORD_MASK
        @value = ""
      end

      protected

      def handle_input(key, _action)
        if Core::Settings.backspace?(key)
          @value = @value.grapheme_clusters[..-2].join
        elsif Core::Settings.printable?(key)
          @value += key
        end
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << help_line
        lines << "#{active_bar}  #{masked_display}\n"
        lines << "#{bar_end}\n"

        validation_lines = validation_message_lines
        if validation_lines.any?
          lines[-1] = validation_lines.first
          lines.concat(validation_lines[1..])
        end

        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        masked = @mask * @value.grapheme_clusters.length
        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(masked)) : Colors.dim(masked)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def masked_display
        masked = @mask * @value.grapheme_clusters.length
        return cursor_block if masked.empty?

        "#{masked}#{cursor_block}"
      end

      def cursor_block = Colors.inverse(Colors.hidden("_"))
    end
  end
end
