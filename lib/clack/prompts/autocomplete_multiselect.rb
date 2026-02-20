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
      include Core::ScrollHelper

      # @param message [String] the prompt message
      # @param options [Array<Hash, String>] list of options to filter
      # @param max_items [Integer] max visible options (default: 5)
      # @param placeholder [String, nil] placeholder text when empty
      # @param required [Boolean] require at least one selection (default: true)
      # @param initial_values [Array, nil] values to pre-select
      # @param filter [Proc, nil] custom filter proc receiving (option_hash, query_string)
      #   and returning true/false. When nil, the default fuzzy matching
      #   across label, value, and hint is used.
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, options:, max_items: 5, placeholder: nil, required: true, initial_values: nil, filter: nil, **opts)
        super(message:, **opts)
        @all_options = normalize_options(options)
        @max_items = max_items
        @placeholder = placeholder
        @required = required
        @filter = filter
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
          @error_message = "Please select at least one option. Press #{Colors.cyan("space")} to select, #{Colors.cyan("enter")} to submit"
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
        lines << "#{active_bar}  #{Colors.dim("Search:")} #{input_display}#{match_count}\n"

        visible_items.each_with_index do |opt, idx|
          actual_idx = @scroll_offset + idx
          lines << "#{active_bar}  #{option_display(opt, actual_idx == @selected_index)}\n"
        end

        lines << "#{active_bar}  #{Colors.yellow("No matches found")}\n" if @filtered.empty? && !@search_text.empty?

        lines << "#{active_bar}  #{instructions}\n"
        lines << "#{bar_end}\n"

        validation_lines = validation_message_lines
        if validation_lines.any?
          lines[-1] = validation_lines.first
          lines.concat(validation_lines[1..])
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

      # Use @search_text as text input backing store
      def text_value = @search_text

      def text_value=(val)
        @search_text = val
      end

      def handle_text_input(key)
        return unless super

        @selected_index = 0
        @scroll_offset = 0
        update_filtered
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
        @filtered = if @filter
          @all_options.select { |opt| @filter.call(opt, @search_text) }
        else
          Core::FuzzyMatcher.filter(@all_options, @search_text)
        end
      end

      def scroll_items = @filtered

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
