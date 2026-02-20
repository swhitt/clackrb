# frozen_string_literal: true

module Clack
  # Interactive prompt implementations (text, select, confirm, etc.).
  module Prompts
    # Single-line text input prompt with cursor navigation.
    #
    # Features:
    # - Arrow key cursor movement (left/right)
    # - Backspace/delete support
    # - Placeholder text (shown when empty)
    # - Default value (used if submitted empty)
    # - Initial value (pre-filled, editable)
    # - Validation support
    # - Tab completion (optional)
    #
    # @example Basic usage
    #   name = Clack.text(message: "What is your name?")
    #
    # @example With all options
    #   name = Clack.text(
    #     message: "Project name?",
    #     placeholder: "my-project",
    #     default_value: "untitled",
    #     initial_value: "hello",
    #     validate: ->(v) { "Required!" if v.empty? }
    #   )
    #
    # @example With tab completion
    #   cmd = Clack.text(
    #     message: "Command?",
    #     completions: %w[build test deploy lint format]
    #   )
    #
    # @example With dynamic completions
    #   cmd = Clack.text(
    #     message: "Command?",
    #     completions: ->(input) { Dir.glob("#{input}*") }
    #   )
    #
    class Text < Core::Prompt
      include Core::TextInputHelper

      # @param message [String] the prompt message
      # @param placeholder [String, nil] dim text shown when input is empty
      # @param default_value [String, nil] value used if submitted empty
      # @param initial_value [String, nil] pre-filled editable text
      # @param completions [Array<String>, Proc, nil] tab completion candidates. Array of
      #   strings or a proc that receives current input and returns candidates.
      # @option opts [Proc, nil] :validate validation proc returning error string or nil
      # @option opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, placeholder: nil, default_value: nil, initial_value: nil, completions: nil, **opts)
        super(message:, **opts)
        @placeholder = placeholder
        @default_value = default_value
        @completions = completions
        @value = initial_value || ""
        @cursor = @value.grapheme_clusters.length
      end

      protected

      def handle_input(key, action)
        # Only use arrow key actions for actual arrow keys, not vim h/l keys
        # which should be treated as text input
        if key&.start_with?("\e[")
          max_cursor = @value.grapheme_clusters.length
          case action
          when :left
            @cursor = [@cursor - 1, 0].max
            return
          when :right
            @cursor = [@cursor + 1, max_cursor].min
            return
          end
        end

        if key == "\t" && @completions
          tab_complete
        else
          handle_text_input(key)
        end
      end

      def submit
        @value = @default_value if @value.empty? && @default_value
        super
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << help_line
        lines << "#{active_bar}  #{input_display}\n"
        lines << "#{bar_end}\n" if @state in :active | :initial

        validation_lines = validation_message_lines
        if validation_lines.any?
          lines[-1] = validation_lines.first
          lines.concat(validation_lines[1..])
        end

        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(@value)) : Colors.dim(@value)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      # Complete the current input using the longest common prefix of matching candidates.
      # Single match: fills the full candidate. Multiple matches: fills the shared prefix.
      def tab_complete
        candidates = if @completions.respond_to?(:call)
          @completions.call(@value)
        else
          @completions.select { |candidate| candidate.downcase.start_with?(@value.downcase) }
        end

        return if candidates.empty?

        completion = if candidates.length == 1
          candidates.first
        else
          common_prefix(candidates)
        end

        return if completion.length <= @value.length

        @value = completion
        @cursor = @value.grapheme_clusters.length
      end

      def common_prefix(strings)
        return "" if strings.empty?

        ref = strings.first
        ref.each_char.with_index do |char, idx|
          return ref[0, idx] unless strings.all? { |s| s[idx]&.downcase == char.downcase }
        end
        ref
      end
    end
  end
end
