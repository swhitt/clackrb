# frozen_string_literal: true

module Clack
  module Prompts
    # Multiple-selection prompt from a list of options.
    #
    # Navigate with arrow keys or j/k. Toggle selection with Space.
    # Supports shortcuts: 'a' to toggle all, 'i' to invert selection.
    #
    # Options format is the same as {Select}.
    #
    # @example Basic usage
    #   features = Clack.multiselect(
    #     message: "Select features",
    #     options: %w[api auth admin]
    #   )
    #
    # @example With options and validation
    #   features = Clack.multiselect(
    #     message: "Select features",
    #     options: [
    #       { value: "api", label: "API Mode" },
    #       { value: "auth", label: "Authentication" }
    #     ],
    #     initial_values: ["api"],
    #     required: true,
    #     max_items: 5
    #   )
    #
    class Multiselect < Core::Prompt
      include Core::OptionsHelper
      include Core::SelectionManager

      # @param message [String] the prompt message
      # @param options [Array<Hash, String>] list of options
      # @param initial_values [Array] values to pre-select
      # @param required [Boolean] require at least one selection (default: true)
      # @param max_items [Integer, nil] max visible items (enables scrolling)
      # @param cursor_at [Object, nil] value to position cursor at initially
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, options:, initial_values: [], required: true, max_items: nil, cursor_at: nil, **opts)
        if opts.key?(:initial_value)
          raise ArgumentError, "Multiselect uses initial_values: (plural), not initial_value:"
        end
        super(message:, **opts)
        @options = normalize_options(options)
        valid_values = Set.new(@options.map { |o| o[:value] })
        @selected = Set.new(initial_values) & valid_values
        @required = required
        @max_items = max_items
        @scroll_offset = 0
        @option_index = find_initial_cursor(cursor_at)
        update_selection_value
      end

      protected

      def handle_input(key, action)
        case action
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
        return unless validate_selection

        super
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << help_line

        visible_options.each_with_index do |opt, idx|
          actual_idx = @scroll_offset + idx
          lines << "#{active_bar}  #{option_display(opt, actual_idx)}\n"
        end

        if @state in :error | :warning
          lines.concat(validation_message_lines)
        else
          lines << "#{bar}  #{keyboard_hints}\n"
          lines << "#{bar_end}\n"
        end

        lines.join
      end

      def final_display = selected_labels(@options)

      private

      def toggle_current
        opt = @options[@option_index]
        return if opt[:disabled]

        toggle_value(opt[:value])
        update_selection_value
      end

      def toggle_all
        enabled = @options.reject { |o| o[:disabled] }.map { |o| o[:value] }
        if enabled.all? { |v| @selected.include?(v) }
          @selected.clear
        else
          @selected.merge(enabled)
        end
        update_selection_value
      end

      def invert_selection
        @options.each do |opt|
          next if opt[:disabled]

          toggle_value(opt[:value])
        end
        update_selection_value
      end

      def keyboard_hints
        hints = [
          "#{Colors.dim("space")} select",
          "#{Colors.dim("a")} all",
          "#{Colors.dim("i")} invert"
        ]
        Colors.dim(hints.join(Colors.dim(" / ")))
      end

      def option_display(opt, idx)
        active = idx == @option_index
        selected = @selected.include?(opt[:value])

        symbol, label = option_parts(opt, active, selected)
        "#{symbol} #{label}"
      end

      def option_parts(opt, active, selected)
        if opt[:disabled]
          return [Colors.dim(Symbols::S_CHECKBOX_INACTIVE),
            Colors.strikethrough(Colors.dim(opt[:label]))]
        end
        return [Colors.green(Symbols::S_CHECKBOX_SELECTED), opt[:label]] if active && selected
        return [Colors.cyan(Symbols::S_CHECKBOX_ACTIVE), opt[:label]] if active
        return [Colors.green(Symbols::S_CHECKBOX_SELECTED), Colors.dim(opt[:label])] if selected

        [Colors.dim(Symbols::S_CHECKBOX_INACTIVE), Colors.dim(opt[:label])]
      end
    end
  end
end
