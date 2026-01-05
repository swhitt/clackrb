module Clack
  module Prompts
    class Password < Core::Prompt
      def initialize(message:, mask: nil, **opts)
        super(message:, **opts)
        @mask = mask || Symbols::S_PASSWORD_MASK
        @value = ""
        @cursor = 0
      end

      protected

      def handle_input(key, _action)
        return unless key && key.length == 1 && key.ord >= 32

        case key
        when "\u007F", "\b"  # Backspace
          return if @cursor == 0
          @value = @value[0...(@cursor - 1)] + @value[@cursor..]
          @cursor -= 1
        else
          @value = @value[0...@cursor] + key + @value[@cursor..]
          @cursor += 1
        end
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << "#{active_bar}  #{masked_display}\n"
        lines << "#{bar_end}\n"

        if @state == :error
          lines[-1] = "#{Colors.yellow(Symbols::S_BAR_END)}  #{Colors.yellow(@error_message)}\n"
        end

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

      def active_bar
        (@state == :error) ? Colors.yellow(Symbols::S_BAR) : bar
      end

      def bar_end
        (@state == :error) ? Colors.yellow(Symbols::S_BAR_END) : Colors.gray(Symbols::S_BAR_END)
      end

      def masked_display
        masked = @mask * @value.length
        return cursor_block if masked.empty?

        return "#{masked}#{cursor_block}" if @cursor >= @value.length

        before = masked[0...@cursor]
        current = Colors.inverse(masked[@cursor])
        after = masked[(@cursor + 1)..]
        "#{before}#{current}#{after}"
      end

      def cursor_block
        Colors.inverse(Colors.hidden("_"))
      end
    end
  end
end
