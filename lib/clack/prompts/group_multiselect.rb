module Clack
  module Prompts
    class GroupMultiselect < Core::Prompt
      def initialize(message:, options:, initial_values: [], required: true, **opts)
        super(message:, **opts)
        @groups = normalize_groups(options)
        @flat_options = flatten_options
        @selected = Set.new(initial_values)
        @required = required
        @cursor = 0
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
        end
      end

      def submit
        if @required && @selected.empty?
          @error_message = "Please select at least one option."
          @state = :error
          return
        end
        super
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        idx = 0
        @groups.each do |group|
          lines << "#{bar}  #{Colors.dim(group[:label])}\n"
          group[:options].each do |opt|
            lines << "#{active_bar}    #{option_display(opt, idx == @cursor)}\n"
            idx += 1
          end
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

        labels = @flat_options.select { |o| @selected.include?(o[:value]) }.map { |o| o[:label] }
        display_text = labels.join(", ")
        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(display_text)) : Colors.dim(display_text)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def normalize_groups(options)
        options.map do |group|
          {
            label: group[:label] || group[:group],
            options: group[:options].map do |opt|
              case opt
              when Hash
                {value: opt[:value], label: opt[:label] || opt[:value].to_s, disabled: opt[:disabled] || false}
              else
                {value: opt, label: opt.to_s, disabled: false}
              end
            end
          }
        end
      end

      def flatten_options
        @groups.flat_map { |g| g[:options] }
      end

      def move_cursor(delta)
        new_cursor = @cursor + delta
        new_cursor = @flat_options.length - 1 if new_cursor < 0
        new_cursor = 0 if new_cursor >= @flat_options.length

        # Skip disabled options
        attempts = @flat_options.length
        while @flat_options[new_cursor][:disabled] && attempts > 0
          new_cursor = (new_cursor + delta) % @flat_options.length
          attempts -= 1
        end

        @cursor = new_cursor
      end

      def toggle_current
        opt = @flat_options[@cursor]
        return if opt[:disabled]

        if @selected.include?(opt[:value])
          @selected.delete(opt[:value])
        else
          @selected.add(opt[:value])
        end
        update_value
      end

      def update_value
        @value = @selected.to_a
      end

      def option_display(opt, active)
        selected = @selected.include?(opt[:value])

        if opt[:disabled]
          "#{Colors.dim(Symbols::S_CHECKBOX_INACTIVE)} #{Colors.strikethrough(Colors.dim(opt[:label]))}"
        elsif active && selected
          "#{Colors.green(Symbols::S_CHECKBOX_SELECTED)} #{opt[:label]}"
        elsif active
          "#{Colors.cyan(Symbols::S_CHECKBOX_ACTIVE)} #{opt[:label]}"
        elsif selected
          "#{Colors.green(Symbols::S_CHECKBOX_SELECTED)} #{Colors.dim(opt[:label])}"
        else
          "#{Colors.dim(Symbols::S_CHECKBOX_INACTIVE)} #{Colors.dim(opt[:label])}"
        end
      end
    end
  end
end
