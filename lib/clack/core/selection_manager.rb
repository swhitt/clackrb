# frozen_string_literal: true

module Clack
  module Core
    # Shared selection management for multi-select prompts.
    # Handles toggle, toggle-all, required validation, and value tracking.
    #
    # Including classes must define:
    # - +@selected+ [Set] the set of selected values
    # - +@required+ [Boolean] whether at least one selection is required
    module SelectionManager
      REQUIRED_ERROR = "Please select at least one option. Press %s to select, %s to submit"

      # Toggle a value in the selection set.
      # @param value [Object] the value to toggle
      def toggle_value(value)
        if @selected.include?(value)
          @selected.delete(value)
        else
          @selected.add(value)
        end
      end

      # Validate that selection meets requirements before submit.
      # Sets error state if required and empty.
      # @return [Boolean] true if valid to proceed with submit
      def validate_selection
        if @required && @selected.empty?
          @error_message = format(REQUIRED_ERROR, Colors.cyan("space"), Colors.cyan("enter"))
          @state = :error
          return false
        end
        true
      end

      # Update @value from the current selection.
      def update_selection_value
        @value = @selected.to_a
      end

      # Build the final display string from selected options.
      # @param all_options [Array<Hash>] the full options list to match against
      # @return [String] comma-separated labels
      def selected_labels(all_options)
        all_options.select { |o| @selected.include?(o[:value]) }.map { |o| o[:label] }.join(", ")
      end
    end
  end
end
