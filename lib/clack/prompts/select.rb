# frozen_string_literal: true

module Clack
  module Prompts
    class Select < Core::Prompt
      include Core::OptionsHelper

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

      def move_cursor(delta)
        super
        update_value
      end

      def update_value
        @value = current_option[:value]
      end

      def current_option
        @options[@cursor]
      end

      def option_display(opt, active)
        return disabled_option_display(opt) if opt[:disabled]
        return active_option_display(opt) if active

        inactive_option_display(opt)
      end

      def disabled_option_display(opt)
        symbol = Colors.dim(Symbols::S_RADIO_INACTIVE)
        label = Colors.strikethrough(Colors.dim(opt[:label]))
        "#{symbol} #{label}"
      end

      def active_option_display(opt)
        symbol = Colors.green(Symbols::S_RADIO_ACTIVE)
        hint = opt[:hint] ? " #{Colors.dim("(#{opt[:hint]})")}" : ""
        "#{symbol} #{opt[:label]}#{hint}"
      end

      def inactive_option_display(opt)
        symbol = Colors.dim(Symbols::S_RADIO_INACTIVE)
        "#{symbol} #{Colors.dim(opt[:label])}"
      end
    end
  end
end
