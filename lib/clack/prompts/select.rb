module Clack
  module Prompts
    class Select < Core::Prompt
      def initialize(message:, options:, initial_value: nil, max_items: nil, **opts)
        super(message:, **opts)
        @options = normalize_options(options)
        @cursor = find_initial_cursor(initial_value)
        @max_items = max_items
        @scroll_offset = 0
        update_value
      end

      protected

      def handle_key(key)
        return if terminal_state?

        action = Core::Settings.action?(key)

        case action
        when :cancel
          @state = :cancel
        when :enter
          submit unless current_option[:disabled]
        when :up, :left
          move_cursor(-1)
        when :down, :right
          move_cursor(1)
        end
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        visible_options.each_with_index do |opt, idx|
          actual_idx = @scroll_offset + idx
          lines << "#{bar}  #{option_display(opt, actual_idx == @cursor)}\n"
        end

        lines << "#{Colors.gray(Symbols::S_BAR_END)}\n"
        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        label = current_option[:label]
        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(label)) : Colors.dim(label)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def normalize_options(options)
        options.map do |opt|
          case opt
          when Hash
            {
              value: opt[:value],
              label: opt[:label] || opt[:value].to_s,
              hint: opt[:hint],
              disabled: opt[:disabled] || false
            }
          else
            {value: opt, label: opt.to_s, hint: nil, disabled: false}
          end
        end
      end

      def find_initial_cursor(initial_value)
        return 0 if initial_value.nil?

        idx = @options.find_index { |o| o[:value] == initial_value }
        (idx && !@options[idx][:disabled]) ? idx : find_next_enabled(0, 1)
      end

      def move_cursor(delta)
        new_cursor = find_next_enabled(@cursor, delta)
        @cursor = new_cursor
        update_scroll
        update_value
      end

      def find_next_enabled(from, delta)
        max = @options.length
        idx = (from + delta) % max

        max.times do
          return idx unless @options[idx][:disabled]
          idx = (idx + delta) % max
        end

        from  # All disabled, stay put
      end

      def update_value
        @value = current_option[:value]
      end

      def current_option
        @options[@cursor]
      end

      def visible_options
        return @options unless @max_items && @options.length > @max_items
        @options[@scroll_offset, @max_items]
      end

      def update_scroll
        return unless @max_items && @options.length > @max_items

        if @cursor < @scroll_offset
          @scroll_offset = @cursor
        elsif @cursor >= @scroll_offset + @max_items
          @scroll_offset = @cursor - @max_items + 1
        end
      end

      def option_display(opt, active)
        if opt[:disabled]
          symbol = Colors.dim(Symbols::S_RADIO_INACTIVE)
          label = Colors.strikethrough(Colors.dim(opt[:label]))
          "#{symbol} #{label}"
        elsif active
          symbol = Colors.green(Symbols::S_RADIO_ACTIVE)
          label = opt[:label]
          hint = opt[:hint] ? " #{Colors.dim("(#{opt[:hint]})")}" : ""
          "#{symbol} #{label}#{hint}"
        else
          symbol = Colors.dim(Symbols::S_RADIO_INACTIVE)
          label = Colors.dim(opt[:label])
          "#{symbol} #{label}"
        end
      end
    end
  end
end
