# frozen_string_literal: true

module Clack
  module Prompts
    # Single-selection prompt from a list of options.
    #
    # Navigate with arrow keys or j/k (vim-style). Press Enter to confirm.
    # Supports disabled options, hints, and scrolling for long lists.
    #
    # Options can be:
    # - Strings: `["a", "b", "c"]` (value and label are the same)
    # - Hashes: `[{value: "a", label: "Option A", hint: "details", disabled: false}]`
    #
    # @example Basic usage
    #   choice = Clack.select(
    #     message: "Pick a color",
    #     options: %w[red green blue]
    #   )
    #
    # @example With rich options
    #   db = Clack.select(
    #     message: "Choose database",
    #     options: [
    #       { value: "pg", label: "PostgreSQL", hint: "recommended" },
    #       { value: "mysql", label: "MySQL" },
    #       { value: "sqlite", label: "SQLite", disabled: true }
    #     ],
    #     initial_value: "pg",
    #     max_items: 5
    #   )
    #
    class Select < Core::Prompt
      include Core::OptionsHelper

      # @param message [String] the prompt message
      # @param options [Array<Hash, String>] list of options (see class docs)
      # @param initial_value [Object, nil] value of initially selected option
      # @param max_items [Integer, nil] max visible items (enables scrolling)
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, options:, initial_value: nil, max_items: nil, **opts)
        super(message:, **opts)
        @options = normalize_options(options)
        @max_items = max_items
        @scroll_offset = 0
        @option_index = find_initial_cursor(initial_value)
        update_value
      end

      protected

      def handle_input(_key, action)
        case action
        when :up, :left then move_cursor(-1)
        when :down, :right then move_cursor(1)
        end
      end

      def can_submit? = !current_option[:disabled]

      def build_frame
        option_lines = visible_options.each_with_index.map do |opt, idx|
          actual_idx = @scroll_offset + idx
          "#{bar}  #{option_display(opt, actual_idx == @option_index)}\n"
        end.join

        "#{frame_header}#{option_lines}#{frame_footer}"
      end

      def final_display = current_option[:label]

      private

      def move_cursor(delta)
        super
        update_value
      end

      def update_value = @value = current_option[:value]

      def current_option = @options[@option_index]

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
