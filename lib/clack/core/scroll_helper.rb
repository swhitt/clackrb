# frozen_string_literal: true

module Clack
  module Core
    # @deprecated Use {OptionsHelper} directly. ScrollHelper is now an alias
    #   for backwards compatibility.
    module ScrollHelper
      def self.included(base)
        base.include(OptionsHelper) unless base.ancestors.include?(OptionsHelper)
      end

      # Alias for visible_options (old name from when ScrollHelper was separate)
      def visible_items
        visible_options
      end

      # Alias for navigable_items (old name from when ScrollHelper was separate)
      def scroll_items
        navigable_items
      end
    end
  end
end
