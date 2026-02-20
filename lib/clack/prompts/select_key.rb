# frozen_string_literal: true

module Clack
  module Prompts
    # Quick selection via keyboard shortcuts.
    #
    # Each option has an associated key. Pressing that key immediately
    # selects the option and submits.
    #
    # Options format:
    # - `{ value: "x", label: "Do X", key: "x" }` - explicit key
    # - `{ value: "create", label: "Create" }` - key defaults to first char
    #
    # @example Basic usage
    #   action = Clack.select_key(
    #     message: "What to do?",
    #     options: [
    #       { value: "create", label: "Create new", key: "c" },
    #       { value: "open", label: "Open existing", key: "o" },
    #       { value: "quit", label: "Quit", key: "q" }
    #     ]
    #   )
    #
    class SelectKey < Core::Prompt
      # @param message [String] the prompt message
      # @param options [Array<Hash>] options with :value, :label, and optionally :key, :hint
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, options:, **opts)
        super(message:, **opts)
        @options = normalize_options(options)
        @value = nil
      end

      protected

      def handle_key(key)
        return if terminal_state?

        action = Core::Settings.action?(key)

        case action
        when :cancel
          @state = :cancel
        else
          opt = @options.find { |o| o[:key]&.downcase == key&.downcase }
          return unless opt

          @value = opt[:value]
          @state = :submit
        end
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << help_line

        @options.each do |opt|
          lines << "#{bar}  #{option_display(opt)}\n"
        end

        lines << "#{Colors.gray(Symbols::S_BAR_END)}\n"
        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        label = @options.find { |o| o[:value] == @value }&.dig(:label).to_s
        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(label)) : Colors.dim(label)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def normalize_options(options)
        options.map do |opt|
          {
            value: opt[:value],
            label: opt[:label] || opt[:value].to_s,
            key: opt[:key] || opt[:value].to_s[0],
            hint: opt[:hint]
          }
        end
      end

      def option_display(opt)
        key_display = Colors.cyan("[#{opt[:key]}]")
        hint = opt[:hint] ? " #{Colors.dim("(#{opt[:hint]})")}" : ""
        "#{key_display} #{opt[:label]}#{hint}"
      end
    end
  end
end
