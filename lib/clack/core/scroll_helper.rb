# frozen_string_literal: true

module Clack
  module Core
    # Shared scroll/navigation logic for filterable option lists.
    #
    # Used by prompts that have a dynamically filtered list (Autocomplete,
    # AutocompleteMultiselect, Path) where the user navigates a subset of
    # options that changes as they type.
    #
    # Including classes must define:
    # - +@max_items+ [Integer] maximum visible items
    # - +@selected_index+ [Integer] current selection index
    # - +@scroll_offset+ [Integer] current scroll position
    #
    # Including classes must implement:
    # - +scroll_items+ [Array] returns the current filterable list
    module ScrollHelper
      # Get the currently visible slice of items based on scroll position.
      #
      # @return [Array] visible items
      def visible_items
        items = scroll_items
        return items if items.length <= @max_items

        items[@scroll_offset, @max_items]
      end

      # Move the selection index by delta, wrapping around.
      #
      # @param delta [Integer] direction (+1 for down, -1 for up)
      def move_selection(delta)
        items = scroll_items
        return if items.empty?

        @selected_index = (@selected_index + delta) % items.length
        update_selection_scroll
      end

      private

      # Update scroll offset to keep the selected index visible.
      def update_selection_scroll
        return unless scroll_items.length > @max_items

        if @selected_index < @scroll_offset
          @scroll_offset = @selected_index
        elsif @selected_index >= @scroll_offset + @max_items
          @scroll_offset = @selected_index - @max_items + 1
        end
      end
    end
  end
end
