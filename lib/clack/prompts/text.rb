# frozen_string_literal: true

module Clack
  module Prompts
    class Text < Core::Prompt
      include Core::TextInputHelper

      def initialize(message:, placeholder: nil, default_value: nil, initial_value: nil, **opts)
        super(message:, **opts)
        @placeholder = placeholder
        @default_value = default_value
        @value = initial_value || ""
        @cursor = @value.length
      end

      protected

      def handle_input(key, action)
        # Only use arrow key actions for actual arrow keys, not vim h/l keys
        # which should be treated as text input
        if key&.start_with?("\e[")
          case action
          when :left
            @cursor = [@cursor - 1, 0].max
            return
          when :right
            @cursor = [@cursor + 1, @value.length].min
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
