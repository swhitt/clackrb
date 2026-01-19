# frozen_string_literal: true

module Clack
  module Prompts
    # Yes/No confirmation prompt.
    #
    # Displays a toggle between two options. Navigate with arrow keys, j/k,
    # or press y/n to select directly.
    #
    # @example Basic usage
    #   proceed = Clack.confirm(message: "Continue?")
    #
    # @example With custom labels
    #   deploy = Clack.confirm(
    #     message: "Deploy to production?",
    #     active: "Yes, ship it!",
    #     inactive: "No, abort",
    #     initial_value: false
    #   )
    #
    class Confirm < Core::Prompt
      # @param message [String] the prompt message
      # @param active [String] label for the "yes" option (default: "Yes")
      # @param inactive [String] label for the "no" option (default: "No")
      # @param initial_value [Boolean] initial selection (default: true)
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, active: "Yes", inactive: "No", initial_value: true, **opts)
        super(message:, **opts)
        @active_label = active
        @inactive_label = inactive
        @value = initial_value
      end

      protected

      def handle_key(key)
        return if terminal_state?

        action = Core::Settings.action?(key)

        case action
        when :cancel
          @state = :cancel
        when :enter
          submit
        when :left, :up
          @value = true
        when :right, :down
          @value = false
        else
          handle_char(key)
        end
      end

      def handle_char(key)
        case key&.downcase
        when "y"
          @value = true
        when "n"
          @value = false
        end
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << help_line
        lines << "#{bar}  #{options_display}\n"
        lines << "#{Colors.gray(Symbols::S_BAR_END)}\n"
        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        selected = @value ? @active_label : @inactive_label
        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(selected)) : Colors.dim(selected)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def options_display
        if @value
          active = "#{Colors.green(Symbols::S_RADIO_ACTIVE)} #{@active_label}"
          inactive = "#{Colors.dim(Symbols::S_RADIO_INACTIVE)} #{Colors.dim(@inactive_label)}"
        else
          active = "#{Colors.dim(Symbols::S_RADIO_INACTIVE)} #{Colors.dim(@active_label)}"
          inactive = "#{Colors.green(Symbols::S_RADIO_ACTIVE)} #{@inactive_label}"
        end

        "#{active} #{Colors.dim("/")} #{inactive}"
      end
    end
  end
end
