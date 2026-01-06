# frozen_string_literal: true

module Clack
  module Prompts
    class Autocomplete < Core::Prompt
      include Core::OptionsHelper
      include Core::TextInputHelper

      def initialize(message:, options:, max_items: 5, placeholder: nil, **opts)
        super(message:, **opts)
        @all_options = normalize_options(options)
        @max_items = max_items
        @placeholder = placeholder
        @value = ""
        @cursor = 0
        @selected_index = 0
        @scroll_offset = 0
        update_filtered
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
          submit_selection
        when :up
          move_selection(-1)
        when :down
          move_selection(1)
        else
          handle_text_input(key)
        end
      end

      def handle_text_input(key)
        return unless super

        @selected_index = 0
        @scroll_offset = 0
        update_filtered
      end

      def submit_selection
        if @filtered.empty?
          @error_message = "No matching option"
          @state = :error
          return
        end

        @value = @filtered[@selected_index][:value]
        submit
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << "#{active_bar}  #{input_display}\n"

        visible_options.each_with_index do |opt, idx|
          actual_idx = @scroll_offset + idx
          lines << "#{bar}  #{option_display(opt, actual_idx == @selected_index)}\n"
        end

        lines << "#{bar_end}\n"

        lines[-1] = "#{Colors.yellow(Symbols::S_BAR_END)}  #{Colors.yellow(@error_message)}\n" if @state == :error

        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        display_value = @filtered[@selected_index]&.[](:label) || @value
        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(display_value)) : Colors.dim(display_value)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def update_filtered
        query = @value.downcase
        @filtered = @all_options.select do |opt|
          opt[:label].downcase.include?(query) ||
            opt[:value].to_s.downcase.include?(query) ||
            opt[:hint]&.downcase&.include?(query)
        end
      end

      def visible_options
        return @filtered if @filtered.length <= @max_items

        @filtered[@scroll_offset, @max_items]
      end

      def move_selection(delta)
        return if @filtered.empty?

        @selected_index = (@selected_index + delta) % @filtered.length
        update_scroll
      end

      def update_scroll
        return unless @filtered.length > @max_items

        if @selected_index < @scroll_offset
          @scroll_offset = @selected_index
        elsif @selected_index >= @scroll_offset + @max_items
          @scroll_offset = @selected_index - @max_items + 1
        end
      end

      def option_display(opt, active)
        hint = (opt[:hint] && active) ? Colors.dim(" (#{opt[:hint]})") : ""
        if active
          "#{Colors.green(Symbols::S_RADIO_ACTIVE)} #{opt[:label]}#{hint}"
        else
          "#{Colors.dim(Symbols::S_RADIO_INACTIVE)} #{Colors.dim(opt[:label])}"
        end
      end
    end
  end
end
