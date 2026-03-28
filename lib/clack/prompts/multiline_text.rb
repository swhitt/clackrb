# frozen_string_literal: true

module Clack
  module Prompts
    # Multi-line text input prompt with line navigation.
    #
    # Features:
    # - Enter inserts newline, Ctrl+D submits
    # - Arrow key navigation (up/down between lines, left/right within line)
    # - Backspace merges lines when at line start
    # - Validation support
    #
    # @example Basic usage
    #   message = Clack.multiline_text(message: "Enter your commit message:")
    #
    # @example With initial value and validation
    #   content = Clack.multiline_text(
    #     message: "Description:",
    #     initial_value: "feat: ",
    #     validate: ->(v) { "Required!" if v.strip.empty? }
    #   )
    #
    class MultilineText < Core::Prompt
      include Core::TextInputHelper

      # @param message [String] the prompt message
      # @param initial_value [String, nil] pre-filled editable text (can contain newlines)
      # @option opts [Proc, nil] :validate validation proc returning error string or nil
      # @option opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, initial_value: nil, **opts)
        super(message:, **opts)
        @lines = parse_initial_value(initial_value)
        @line_index = @lines.length - 1
        @cursor = current_line.grapheme_clusters.length
      end

      protected

      def handle_key(key)
        return if terminal_state?

        case key
        when Core::Settings::KEY_CTRL_D
          submit
        when Core::Settings::KEY_ESCAPE, Core::Settings::KEY_CTRL_C
          @state = :cancel
        when Core::Settings::KEY_ENTER, Core::Settings::KEY_NEWLINE
          insert_newline
        else
          handle_input(key)
        end
      end

      def handle_input(key)
        case key
        when "\e[A" then move_up
        when "\e[B" then move_down
        when "\e[C" then move_right
        when "\e[D" then move_left
        else handle_text_input(key)
        end
      end

      def submit
        @value = @lines.join("\n")
        super
      end

      def frame_header
        "#{bar}\n#{symbol_for_state}  #{@message} #{Colors.dim("(Ctrl+D to submit)")}\n#{help_line}"
      end

      def build_frame
        body = @lines.each_with_index.map do |line, idx|
          display = (idx == @line_index) ? value_with_cursor : line
          "#{active_bar}  #{display}\n"
        end.join

        "#{frame_header}#{body}#{frame_footer}"
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        if @state == :cancel
          @lines.each { |line| lines << "#{bar}  #{Colors.strikethrough(Colors.dim(line))}\n" }
        else
          @lines.each { |line| lines << "#{bar}  #{Colors.dim(line)}\n" }
        end

        lines.join
      end

      # TextInputHelper backing store: delegate to current line.
      def text_value = current_line

      def text_value=(val)
        @lines[@line_index] = val
      end

      private

      def parse_initial_value(value)
        return [""] if value.nil? || value.empty?

        value.split("\n", -1) # -1 preserves trailing empty strings
      end

      def current_line = @lines[@line_index] || ""

      def insert_newline
        chars = current_line.grapheme_clusters
        before = chars[0...@cursor].join
        after = chars[@cursor..].join

        @lines[@line_index] = before
        @lines.insert(@line_index + 1, after)
        @line_index += 1
        @cursor = 0
      end

      def move_up
        return if @line_index.zero?

        @line_index -= 1
        clamp_column
      end

      def move_down
        return if @line_index >= @lines.length - 1

        @line_index += 1
        clamp_column
      end

      def move_left
        return if @cursor.zero?

        @cursor -= 1
      end

      def move_right
        max = current_line.grapheme_clusters.length
        return if @cursor >= max

        @cursor += 1
      end

      def clamp_column
        max = current_line.grapheme_clusters.length
        @cursor = [@cursor, max].min
      end

      # Override backspace to handle line merging at column 0
      def handle_backspace
        if @cursor.zero?
          return false if @line_index.zero?

          merge_line_up
          true
        else
          super
        end
      end

      def merge_line_up
        return if @line_index.zero?

        current_content = @lines.delete_at(@line_index)
        @line_index -= 1
        prev_length = current_line.grapheme_clusters.length
        @lines[@line_index] = current_line + current_content
        @cursor = prev_length
      end
    end
  end
end
