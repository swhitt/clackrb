# frozen_string_literal: true

module Clack
  module Core
    # Shared functionality for option-based prompts (Select, Multiselect).
    # Handles option normalization, cursor navigation, and scrolling.
    module OptionsHelper
      # Normalize options to a consistent hash format.
      # Accepts strings, symbols, or hashes with value/label/hint/disabled keys.
      #
      # @param options [Array] Raw options in various formats
      # @return [Array<Hash>] Normalized option hashes
      def normalize_options(options)
        options.map do |opt|
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
      end

      # Find the next enabled option in the given direction.
      # Wraps around the list if necessary.
      #
      # @param from [Integer] Starting index
      # @param delta [Integer] Direction (+1 for forward, -1 for backward)
      # @return [Integer] Index of next enabled option, or from if all disabled
      def find_next_enabled(from, delta)
        max = @options.length
        idx = (from + delta) % max

        max.times do
          return idx unless @options[idx][:disabled]

          idx = (idx + delta) % max
        end

        from
      end

      # Move cursor in the given direction, skipping disabled options.
      #
      # @param delta [Integer] Direction (+1 for down/right, -1 for up/left)
      def move_cursor(delta)
        @cursor = find_next_enabled(@cursor, delta)
        update_scroll
      end

      # Get the currently visible options based on scroll offset and max_items.
      #
      # @return [Array<Hash>] Visible options
      def visible_options
        return @options unless @max_items && @options.length > @max_items

        @options[@scroll_offset, @max_items]
      end

      # Update scroll offset to keep cursor visible within the window.
      def update_scroll
        return unless @max_items && @options.length > @max_items

        if @cursor < @scroll_offset
          @scroll_offset = @cursor
        elsif @cursor >= @scroll_offset + @max_items
          @scroll_offset = @cursor - @max_items + 1
        end
      end

      # Find initial cursor position based on initial value or first enabled option.
      #
      # @param initial_value [Object, nil] Initial value to select
      # @return [Integer] Cursor position
      def find_initial_cursor(initial_value)
        return 0 if @options.empty?

        if initial_value.nil?
          # Start at first enabled option
          return @options[0][:disabled] ? find_next_enabled(-1, 1) : 0
        end

        idx = @options.find_index { |o| o[:value] == initial_value }
        (idx && !@options[idx][:disabled]) ? idx : find_next_enabled(-1, 1)
      end
    end
  end
end
