# frozen_string_literal: true

module Clack
  module Prompts
    # Single-line text input prompt with cursor navigation.
    #
    # Features:
    # - Arrow key cursor movement (left/right)
    # - Backspace/delete support
    # - Placeholder text (shown when empty)
    # - Default value (used if submitted empty)
    # - Initial value (pre-filled, editable)
    # - Validation support
    #
    # @example Basic usage
    #   name = Clack.text(message: "What is your name?")
    #
    # @example With all options
    #   name = Clack.text(
    #     message: "Project name?",
    #     placeholder: "my-project",
    #     default_value: "untitled",
    #     initial_value: "hello",
    #     validate: ->(v) { "Required!" if v.empty? }
    #   )
    #
    class Text < Core::Prompt
      include Core::TextInputHelper

      # @param message [String] the prompt message
      # @param placeholder [String, nil] dim text shown when input is empty
      # @param default_value [String, nil] value used if submitted empty
      # @param initial_value [String, nil] pre-filled editable text
      # @param validate [Proc, nil] validation proc returning error string or nil
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, placeholder: nil, default_value: nil, initial_value: nil, **opts)
        super(message:, **opts)
        @placeholder = placeholder
        @default_value = default_value
        @value = initial_value || ""
        @cursor = @value.grapheme_clusters.length
      end

      protected

      def handle_input(key, action)
        # Only use arrow key actions for actual arrow keys, not vim h/l keys
        # which should be treated as text input
        if key&.start_with?("\e[")
          max_cursor = @value.grapheme_clusters.length
          case action
          when :left
            @cursor = [@cursor - 1, 0].max
            return
          when :right
            @cursor = [@cursor + 1, max_cursor].min
            return
          end
        end

        handle_text_input(key)
      end

      def submit
        @value = @default_value if @value.empty? && @default_value
        super
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << "#{active_bar}  #{input_display}\n"
        lines << "#{bar_end}\n" if @state == :active || @state == :initial

        lines[-1] = "#{Colors.yellow(Symbols::S_BAR_END)}  #{Colors.yellow(@error_message)}\n" if @state == :error

        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(@value)) : Colors.dim(@value)
        lines << "#{bar}  #{display}\n"

        lines.join
      end
    end
  end
end
