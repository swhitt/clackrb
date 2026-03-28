# frozen_string_literal: true

module Clack
  module Core
    # Shared functionality for option-based prompts (Select, Multiselect, Autocomplete, etc.).
    # Handles option normalization, cursor navigation, and scrolling.
    #
    # Including classes must define:
    # - +@max_items+ [Integer, nil] maximum visible items (nil = show all)
    # - +@option_index+ [Integer] current selection index
    # - +@scroll_offset+ [Integer] current scroll position
    #
    # Including classes must implement:
    # - +navigable_items+ [Array] returns the current list to navigate
    module OptionsHelper
      # Normalize options to a consistent hash format.
      # Accepts strings, symbols, or hashes with value/label/hint/disabled keys.
      #
      # @param options [Array] Raw options in various formats
      # @return [Array<Hash>] Normalized option hashes
      # @raise [ArgumentError] if options is empty
      def normalize_options(options)
        raise ArgumentError, "options cannot be empty" if options.nil? || options.empty?

        options.map { |opt| OptionsHelper.normalize_option(opt) }
      end

      # Normalize a single option to a consistent hash format.
      # @param opt [Hash, String, Symbol] Raw option
      # @return [Hash] Normalized option hash
      def self.normalize_option(opt)
        case opt
        when Hash
          {
            value: opt[:value],
            label: opt[:label] || opt[:value].to_s,
            hint: opt[:hint],
            disabled: opt[:disabled] || false
          }
        else
          {value: opt, label: opt.to_s, hint: nil, disabled: false}
        end
      end

      # Find the next enabled option in the given direction.
      # Wraps around the list if necessary.
      #
      # @param from [Integer] Starting index
      # @param delta [Integer] Direction (+1 for forward, -1 for backward)
      # @return [Integer] Index of next enabled option, or from if all disabled
      def find_next_enabled(from, delta)
        items = navigable_items
        max = items.length
        idx = (from + delta) % max

        max.times do
          return idx unless items[idx][:disabled]

          idx = (idx + delta) % max
        end

        from
      end

      # Index of the first enabled option.
      # @return [Integer]
      def first_enabled_index
        find_next_enabled(-1, 1)
      end

      # Move option_index in the given direction, skipping disabled options.
      #
      # @param delta [Integer] Direction (+1 for down/right, -1 for up/left)
      def move_cursor(delta)
        @option_index = find_next_enabled(@option_index, delta)
        update_scroll
      end

      # Move the selection index by delta, wrapping around.
      # Unlike move_cursor, does not skip disabled items.
      #
      # @param delta [Integer] direction (+1 for down, -1 for up)
      def move_selection(delta)
        items = navigable_items
        return if items.empty?

        @option_index = (@option_index + delta) % items.length
        update_scroll
      end

      # Get the currently visible options based on scroll offset and max_items.
      #
      # @return [Array<Hash>] Visible options
      def visible_options
        items = navigable_items
        return items unless @max_items && items.length > @max_items

        items[@scroll_offset, @max_items]
      end

      # Update scroll offset to keep option_index visible within the window.
      def update_scroll
        items = navigable_items
        return unless @max_items && items.length > @max_items

        if @option_index < @scroll_offset
          @scroll_offset = @option_index
        elsif @option_index >= @scroll_offset + @max_items
          @scroll_offset = @option_index - @max_items + 1
        end
      end

      # Find initial cursor position based on initial value or first enabled option.
      #
      # @param initial_value [Object, nil] Initial value to select
      # @return [Integer] Cursor position
      def find_initial_cursor(initial_value)
        items = navigable_items
        return 0 if items.empty?

        if initial_value.nil?
          # Start at first enabled option
          return items[0][:disabled] ? first_enabled_index : 0
        end

        idx = items.find_index { |o| o[:value] == initial_value }
        (idx && !items[idx][:disabled]) ? idx : first_enabled_index
      end

      # The list of items to navigate. Override in subclasses that use
      # a filtered or dynamic list (e.g., Autocomplete uses @filtered).
      # @return [Array]
      def navigable_items
        @options
      end
    end
  end
end
