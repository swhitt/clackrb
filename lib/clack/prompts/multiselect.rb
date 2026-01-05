module Clack
  module Prompts
    class Multiselect < Core::Prompt
      def initialize(message:, options:, initial_values: [], required: true, max_items: nil, cursor_at: nil, **opts)
        super(message:, **opts)
        @options = normalize_options(options)
        @selected = Set.new(initial_values)
        @required = required
        @max_items = max_items
        @scroll_offset = 0
        @cursor = find_initial_cursor(cursor_at)
        update_value
      end

      protected

      def handle_key(key)
        return if terminal_state?

        @state = :active if @state == :error
        action = Core::Settings.action?(key)

        case action
        when :cancel
          @state = :cancel
        when :enter
          submit
        when :up
          move_cursor(-1)
        when :down
          move_cursor(1)
        when :space
          toggle_current
        else
          handle_char(key)
        end
      end

      def handle_char(key)
        case key&.downcase
        when "a"
          toggle_all
        when "i"
          invert_selection
        end
      end

      def submit
        if @required && @selected.empty?
          @error_message = "Please select at least one option.\nPress #{Colors.cyan("space")} to select, #{Colors.cyan("enter")} to submit"
          @state = :error
          return
        end
        super
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        visible_options.each_with_index do |opt, idx|
          actual_idx = @scroll_offset + idx
          lines << "#{active_bar}  #{option_display(opt, actual_idx)}\n"
        end

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

        labels = @options.select { |o| @selected.include?(o[:value]) }.map { |o| o[:label] }
        display_text = labels.join(", ")
        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(display_text)) : Colors.dim(display_text)
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

      def find_initial_cursor(cursor_at)
        return 0 if cursor_at.nil?

        idx = @options.find_index { |o| o[:value] == cursor_at }
        (idx && !@options[idx][:disabled]) ? idx : 0
      end

      def move_cursor(delta)
        new_cursor = find_next_enabled(@cursor, delta)
        @cursor = new_cursor
        update_scroll
      end

      def find_next_enabled(from, delta)
        max = @options.length
        idx = (from + delta) % max

        max.times do
          return idx unless @options[idx][:disabled]
          idx = (idx + delta) % max
        end

        from
      end

      def toggle_current
        opt = @options[@cursor]
        return if opt[:disabled]

        if @selected.include?(opt[:value])
          @selected.delete(opt[:value])
        else
          @selected.add(opt[:value])
        end
        update_value
      end

      def toggle_all
        enabled = @options.reject { |o| o[:disabled] }.map { |o| o[:value] }
        if enabled.all? { |v| @selected.include?(v) }
          @selected.clear
        else
          @selected.merge(enabled)
        end
        update_value
      end

      def invert_selection
        @options.each do |opt|
          next if opt[:disabled]
          if @selected.include?(opt[:value])
            @selected.delete(opt[:value])
          else
            @selected.add(opt[:value])
          end
        end
        update_value
      end

      def update_value
        @value = @selected.to_a
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

      def active_bar
        (@state == :error) ? Colors.yellow(Symbols::S_BAR) : bar
      end

      def bar_end
        (@state == :error) ? Colors.yellow(Symbols::S_BAR_END) : Colors.gray(Symbols::S_BAR_END)
      end

      def option_display(opt, idx)
        active = idx == @cursor
        selected = @selected.include?(opt[:value])

        symbol, label = option_parts(opt, active, selected)
        "#{symbol} #{label}"
      end

      def option_parts(opt, active, selected)
        if opt[:disabled]
          [Colors.dim(Symbols::S_CHECKBOX_INACTIVE), Colors.strikethrough(Colors.dim(opt[:label]))]
        elsif active && selected
          [Colors.green(Symbols::S_CHECKBOX_SELECTED), opt[:label]]
        elsif active
          [Colors.cyan(Symbols::S_CHECKBOX_ACTIVE), opt[:label]]
        elsif selected
          [Colors.green(Symbols::S_CHECKBOX_SELECTED), Colors.dim(opt[:label])]
        else
          [Colors.dim(Symbols::S_CHECKBOX_INACTIVE), Colors.dim(opt[:label])]
        end
      end
    end
  end
end
