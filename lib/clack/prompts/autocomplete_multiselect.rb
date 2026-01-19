# frozen_string_literal: true

module Clack
  module Prompts
    # Type-to-filter autocomplete with multiple selection.
    #
    # Combines text input filtering with checkbox-style selection.
    # Type to filter, Space to toggle, Enter to confirm.
    #
    # Shortcuts:
    # - Space: toggle current option
    # - 'a': toggle all options
    # - 'i': invert selection
    #
    # @example Basic usage
    #   colors = Clack.autocomplete_multiselect(
    #     message: "Pick colors",
    #     options: %w[red orange yellow green blue]
    #   )
    #
    # @example With options
    #   tags = Clack.autocomplete_multiselect(
    #     message: "Select tags",
    #     options: all_tags,
    #     placeholder: "Type to filter...",
    #     required: true,
    #     initial_values: ["important"]
    #   )
    #
    class AutocompleteMultiselect < Core::Prompt
      include Core::OptionsHelper
      include Core::TextInputHelper

      # @param message [String] the prompt message
      # @param options [Array<Hash, String>] list of options to filter
      # @param max_items [Integer] max visible options (default: 5)
      # @param placeholder [String, nil] placeholder text when empty
      # @param required [Boolean] require at least one selection (default: true)
      # @param initial_values [Array, nil] values to pre-select
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, options:, max_items: 5, placeholder: nil, required: true, initial_values: nil, **opts)
        super(message:, **opts)
        @all_options = normalize_options(options)
        @max_items = max_items
        @placeholder = placeholder
        @required = required
        @search_text = ""
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
        # Shortcut keys only work when search field is empty
        # to avoid interfering with typing filter text
        if @search_text.empty?
          case key&.downcase
          when "a"
            toggle_all
            return
          when "i"
            invert_selection
            return
          end
        end
        handle_text_input(key)
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
        lines << help_line
        lines << "#{active_bar}  #{Colors.dim("Search:")} #{search_input_display}#{match_count}\n"

        visible_options.each_with_index do |opt, idx|
          actual_idx = @scroll_offset + idx
          lines << "#{active_bar}  #{option_display(opt, actual_idx == @selected_index)}\n"
        end

        lines << "#{active_bar}  #{Colors.yellow("No matches found")}\n" if @filtered.empty? && !@search_text.empty?

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
          Colors.strikethrough(Colors.dim("cancelled"))
        else
          Colors.dim("#{@selected_values.size} items selected")
        end
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      # Override TextInputHelper methods to use @search_text instead of @value
      def search_input_display
        return placeholder_display if @search_text.empty?

        search_value_with_cursor
      end

      def search_value_with_cursor
        chars = @search_text.grapheme_clusters
        return "#{@search_text}#{cursor_block}" if @cursor >= chars.length

        before = chars[0...@cursor].join
        current = Colors.inverse(chars[@cursor])
        after = chars[(@cursor + 1)..].join
        "#{before}#{current}#{after}"
      end

      # Override to work with @search_text instead of @value
      def handle_text_input(key)
        return false unless Core::Settings.printable?(key)

        chars = @search_text.grapheme_clusters

        if Core::Settings.backspace?(key)
          return false if @cursor.zero?

          chars.delete_at(@cursor - 1)
          @search_text = chars.join
          @cursor -= 1
        else
          chars.insert(@cursor, key)
          @search_text = chars.join
          @cursor += 1
        end

        @selected_index = 0
        @scroll_offset = 0
        update_filtered
        true
      end

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
        query = @search_text.downcase
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
