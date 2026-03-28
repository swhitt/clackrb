# frozen_string_literal: true

module Clack
  module Prompts
    # Type-to-filter autocomplete prompt.
    #
    # Combines text input with a filtered option list. Type to filter,
    # use arrow keys to navigate matches, Enter to select.
    #
    # By default, filtering uses fuzzy matching across value, label, and
    # hint fields, sorted by relevance score. Supply a custom +filter+
    # proc to override this behavior.
    #
    # @example Basic usage
    #   color = Clack.autocomplete(
    #     message: "Pick a color",
    #     options: %w[red orange yellow green blue indigo violet]
    #   )
    #
    # @example With placeholder
    #   city = Clack.autocomplete(
    #     message: "Select city",
    #     options: cities,
    #     placeholder: "Type to search...",
    #     max_items: 10
    #   )
    #
    # @example Custom filter
    #   Clack.autocomplete(
    #     message: "Select command",
    #     options: commands,
    #     filter: ->(opt, query) { opt[:label].start_with?(query) }
    #   )
    #
    class Autocomplete < Core::Prompt
      include Core::OptionsHelper
      include Core::TextInputHelper

      # @param message [String] the prompt message
      # @param options [Array<Hash, String>] list of options to filter
      # @param max_items [Integer] max visible options (default: 5)
      # @param placeholder [String, nil] placeholder text when empty
      # @param filter [Proc, nil] custom filter proc receiving (option_hash, query_string)
      #   and returning true/false. When nil, the default fuzzy matching
      #   across label, value, and hint is used.
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, options:, max_items: 5, placeholder: nil, filter: nil, **opts)
        super(message:, **opts)
        @all_options = normalize_options(options)
        @max_items = max_items
        @placeholder = placeholder
        @filter = filter
        @search_text = ""
        @cursor = 0
        @option_index = 0
        @scroll_offset = 0
        update_filtered
      end

      protected

      def handle_key(key)
        return if terminal_state?

        # Printable characters always feed the search field.
        # This prevents vim aliases (j/k/h/l) from hijacking text input.
        if Core::Settings.printable?(key)
          handle_text_input(key)
          return
        end

        action = Core::Settings.action?(key)

        case action
        when :cancel then @state = :cancel
        when :enter then submit_selection
        when :up then move_selection(-1)
        when :down then move_selection(1)
        else handle_text_input(key)
        end
      end

      # Use @search_text as text input backing store
      def text_value = @search_text

      def text_value=(val)
        @search_text = val
      end

      def handle_text_input(key)
        return unless super

        @option_index = 0
        @scroll_offset = 0
        update_filtered
      end

      def submit_selection
        if @filtered.empty?
          @error_message = "No matching option"
          @state = :error
          return
        end

        @value = @filtered[@option_index][:value]
        submit
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << help_line
        lines << "#{active_bar}  #{input_display}\n"

        visible_options.each_with_index do |opt, idx|
          actual_idx = @scroll_offset + idx
          lines << "#{bar}  #{option_display(opt, actual_idx == @option_index)}\n"
        end

        if @state in :error | :warning
          lines.concat(validation_message_lines)
        else
          lines << "#{bar_end}\n"
        end

        lines.join
      end

      def final_display = @filtered[@option_index]&.[](:label) || @value

      private

      def update_filtered
        @filtered = if @filter
          @all_options.select { |opt| @filter.call(opt, @search_text) }
        else
          Core::FuzzyMatcher.filter(@all_options, @search_text)
        end
      end

      def navigable_items = @filtered

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
