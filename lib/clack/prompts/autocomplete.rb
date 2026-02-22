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
      include Core::ScrollHelper

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
        @value = ""
        @cursor = 0
        @selected_index = 0
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
        lines << help_line
        lines << "#{active_bar}  #{input_display}\n"

        visible_items.each_with_index do |opt, idx|
          actual_idx = @scroll_offset + idx
          lines << "#{bar}  #{option_display(opt, actual_idx == @selected_index)}\n"
        end

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

        display_value = @filtered[@selected_index]&.[](:label) || @value
        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(display_value)) : Colors.dim(display_value)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def update_filtered
        @filtered = if @filter
          @all_options.select { |opt| @filter.call(opt, @value) }
        else
          Core::FuzzyMatcher.filter(@all_options, @value)
        end
      end

      def scroll_items = @filtered

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
