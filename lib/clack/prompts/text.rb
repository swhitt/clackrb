module Clack
  module Prompts
    class Text < Core::Prompt
      def initialize(message:, placeholder: nil, default_value: nil, initial_value: nil, **opts)
        super(message:, **opts)
        @placeholder = placeholder
        @default_value = default_value
        @value = initial_value || ""
        @cursor = @value.length
      end

      protected

      def handle_input(key, action)
        case action
        when :left
          @cursor = [@cursor - 1, 0].max
        when :right
          @cursor = [@cursor + 1, @value.length].min
        else
          handle_text_input(key)
        end
      end

      def handle_text_input(key)
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

        if @state == :error
          lines[-1] = "#{Colors.yellow(Symbols::S_BAR_END)}  #{Colors.yellow(@error_message)}\n"
        end

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

      private

      def active_bar
        case @state
        when :error then Colors.yellow(Symbols::S_BAR)
        else bar
        end
      end

      def bar_end
        case @state
        when :error then Colors.yellow(Symbols::S_BAR_END)
        else Colors.gray(Symbols::S_BAR_END)
        end
      end

      def input_display
        return placeholder_display if @value.empty?
        value_with_cursor
      end

      def placeholder_display
        return cursor_block if @placeholder.nil? || @placeholder.empty?

        first = Colors.inverse(@placeholder[0])
        rest = Colors.dim(@placeholder[1..])
        "#{first}#{rest}"
      end

      def value_with_cursor
        return "#{@value}#{cursor_block}" if @cursor >= @value.length

        before = @value[0...@cursor]
        current = Colors.inverse(@value[@cursor])
        after = @value[(@cursor + 1)..]
        "#{before}#{current}#{after}"
      end

      def cursor_block
        Colors.inverse(" ")
      end
    end
  end
end
