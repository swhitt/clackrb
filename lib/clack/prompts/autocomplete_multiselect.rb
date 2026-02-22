# frozen_string_literal: true

module Clack
  module Prompts
    # Type-to-filter autocomplete with multiple selection.
    #
    # Combines text input filtering with checkbox-style selection.
    # Type to filter, Space to toggle, Enter to confirm.
    #
    # Unlike {Multiselect}, the 'a' (select all) and 'i' (invert) shortcuts
    # are not available because those characters are needed for the search field.
    # Similarly, vim-style j/k navigation is disabled in favor of typing.
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
      # @param initial_values [Array] values to pre-select
      # @param filter [Proc, nil] custom filter proc receiving (option_hash, query_string)
      #   and returning true/false. When nil, the default fuzzy matching
      #   across label, value, and hint is used.
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, options:, max_items: 5, placeholder: nil, required: true, initial_values: [], filter: nil, **opts)
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
        valid_values = Set.new(@all_options.map { |o| o[:value] })
        @selected = Set.new(initial_values) & valid_values
        update_filtered
      end

      protected

      def handle_key(key)
        return if terminal_state?

        # Printable characters always feed the search field (except space, which toggles).
        # This prevents vim aliases (j/k/h/l) from hijacking text input.
        if Core::Settings.printable?(key) && key != " "
          handle_text_input(key)
          return
        end

        action = Core::Settings.action?(key)

        case action
        when :cancel then @state = :cancel
        when :enter then submit
        when :up then move_selection(-1)
        when :down then move_selection(1)
        when :space then toggle_current
        else handle_text_input(key)
        end
      end

      def toggle_current
        return if @filtered.empty?

        opt = @filtered[@selected_index]
        return if opt[:disabled]

        if @selected.include?(opt[:value])
          @selected.delete(opt[:value])
        else
          @selected.add(opt[:value])
        end
      end

      def submit
        if @required && @selected.empty?
          @error_message = "Please select at least one option. Press #{Colors.cyan("space")} to select, #{Colors.cyan("enter")} to submit"
          @state = :error
          return
        end

        @value = @selected.to_a
        super
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

        lines << "#{active_bar}  #{keyboard_hints}\n"

        if @state in :error | :warning
          lines.concat(validation_message_lines)
        else
          lines << "#{bar_end}\n"
        end

        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        labels = @all_options.select { |o| @selected.include?(o[:value]) }.map { |o| o[:label] }
        display_text = labels.join(", ")
        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(display_text)) : Colors.dim(display_text)
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

      def keyboard_hints
        Colors.dim([
          "up/down: navigate",
          "space: select",
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
        selected = @selected.include?(opt[:value])
        checkbox = if selected
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
