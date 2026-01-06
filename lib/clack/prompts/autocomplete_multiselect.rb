# frozen_string_literal: true

module Clack
  module Prompts
    # Autocomplete with multiselect - type to filter, space to toggle selection
    class AutocompleteMultiselect < Core::Prompt
      include Core::OptionsHelper
      include Core::TextInputHelper

      def initialize(message:, options:, max_items: 5, placeholder: nil, required: true, initial_values: nil, **opts)
        super(message:, **opts)
        @all_options = normalize_options(options)
        @max_items = max_items
        @placeholder = placeholder
        @required = required
        @value = ""
        @cursor = 0
        @selected_index = 0
        @scroll_offset = 0
        @selected_values = Set.new(initial_values || [])
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

      def toggle_current
        return if @filtered.empty?

        current_value = @filtered[@selected_index][:value]
        if @selected_values.include?(current_value)
          @selected_values.delete(current_value)
        else
          @selected_values.add(current_value)
        end
      end

      def toggle_all
        if @selected_values.size == @all_options.size
          @selected_values.clear
        else
          @all_options.each { |opt| @selected_values.add(opt[:value]) }
        end
      end

      def invert_selection
        @all_options.each do |opt|
          if @selected_values.include?(opt[:value])
            @selected_values.delete(opt[:value])
          else
            @selected_values.add(opt[:value])
          end
        end
      end

      def submit_selection
        if @required && @selected_values.empty?
          @error_message = "Please select at least one option"
          @state = :error
          return
        end

        @value = @selected_values.to_a
        submit
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << "#{active_bar}  #{Colors.dim("Search:")} #{input_display}#{match_count}\n"

        visible_options.each_with_index do |opt, idx|
          actual_idx = @scroll_offset + idx
          lines << "#{active_bar}  #{option_display(opt, actual_idx == @selected_index)}\n"
        end

        lines << "#{active_bar}  #{Colors.yellow("No matches found")}\n" if @filtered.empty? && !@value.empty?

        lines << "#{active_bar}  #{instructions}\n"
        lines << "#{bar_end}\n"

        if @state == :error
          lines[-2] = "#{Colors.yellow(Symbols::S_BAR)}  #{Colors.yellow(@error_message)}\n"
          lines[-1] = "#{Colors.yellow(Symbols::S_BAR_END)}\n"
        end

        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        display = if @state == :cancel
          Colors.strikethrough(Colors.dim(@value.to_s))
        else
          Colors.dim("#{@selected_values.size} items selected")
        end
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def match_count
        return "" if @filtered.size == @all_options.size

        Colors.dim(" (#{@filtered.size} match#{"es" unless @filtered.size == 1})")
      end

      def instructions
        Colors.dim([
          "up/down: navigate",
          "space: select",
          "a: all",
          "i: invert",
          "enter: confirm"
        ].join(" | "))
      end

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
        is_selected = @selected_values.include?(opt[:value])
        checkbox = if is_selected
          Colors.green(Symbols::S_CHECKBOX_SELECTED)
        else
          Colors.dim(Symbols::S_CHECKBOX_INACTIVE)
        end

        label = active ? opt[:label] : Colors.dim(opt[:label])
        hint = (opt[:hint] && active) ? Colors.dim(" (#{opt[:hint]})") : ""

        "#{checkbox} #{label}#{hint}"
      end
    end
  end
end
