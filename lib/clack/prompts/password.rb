# frozen_string_literal: true

module Clack
  module Prompts
    class Password < Core::Prompt
      def initialize(message:, mask: nil, **opts)
        super(message:, **opts)
        @mask = mask || Symbols::S_PASSWORD_MASK
        @value = ""
      end

      protected

      def handle_input(key, _action)
        return unless Core::Settings.printable?(key)

        if Core::Settings.backspace?(key)
          @value = @value.chop
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

        masked = @mask * @value.length
        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(masked)) : Colors.dim(masked)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def masked_display
        masked = @mask * @value.length
        return cursor_block if masked.empty?

        "#{masked}#{cursor_block}"
      end

      def cursor_block
        Colors.inverse(Colors.hidden("_"))
      end
    end
  end
end
