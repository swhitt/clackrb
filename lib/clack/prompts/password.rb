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
      # @param validate [Proc, nil] validation proc returning error string or nil
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, mask: nil, **opts)
        super(message:, **opts)
        @mask = mask || Symbols::S_PASSWORD_MASK
        @value = ""
      end

      protected

      def handle_input(key, _action)
        return unless Core::Settings.printable?(key)

        if Core::Settings.backspace?(key)
          clusters = @value.grapheme_clusters
          @value = (clusters.length > 0) ? clusters[0..-2].join : ""
        else
          @value += key
        end
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << "#{active_bar}  #{masked_display}\n"
        lines << "#{bar_end}\n"

        lines[-1] = "#{Colors.yellow(Symbols::S_BAR_END)}  #{Colors.yellow(@error_message)}\n" if @state == :error

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

      def cursor_block
        Colors.inverse(Colors.hidden("_"))
      end
    end
  end
end
