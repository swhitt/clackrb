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
      # @param message [String] the prompt message
      # @param initial_value [String, nil] pre-filled editable text (can contain newlines)
      # @option opts [Proc, nil] :validate validation proc returning error string or nil
      # @option opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, initial_value: nil, **opts)
        super(message:, **opts)
        @lines = parse_initial_value(initial_value)
        @line_index = @lines.length - 1
        @column = current_line.grapheme_clusters.length
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

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message} #{Colors.dim("(Ctrl+D to submit)")}\n"
        lines << help_line

        @lines.each_with_index do |line, idx|
          display = (idx == @line_index) ? line_with_cursor(line) : line
          lines << "#{active_bar}  #{display}\n"
        end

        if @state in :error | :warning
          lines.concat(validation_message_lines)
        else
          lines << "#{bar_end}\n"
        end

        lines.join
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

      private

      def parse_initial_value(value)
        return [""] if value.nil? || value.empty?

        value.split("\n", -1) # -1 preserves trailing empty strings
      end

      def current_line = @lines[@line_index] || ""

      def line_with_cursor(line)
        chars = line.grapheme_clusters
        return cursor_block if chars.empty?
        return "#{line}#{cursor_block}" if @column >= chars.length

        before = chars[0...@column].join
        current = Colors.inverse(chars[@column])
        after = chars[(@column + 1)..].join
        "#{before}#{current}#{after}"
      end

      def insert_newline
        chars = current_line.grapheme_clusters
        before = chars[0...@column].join
        after = chars[@column..].join

        @lines[@line_index] = before
        @lines.insert(@line_index + 1, after)
        @line_index += 1
        @column = 0
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
        return if @column.zero?

        @column -= 1
      end

      def move_right
        max = current_line.grapheme_clusters.length
        return if @column >= max

        @column += 1
      end

      def clamp_column
        max = current_line.grapheme_clusters.length
        @column = [@column, max].min
      end

      def handle_text_input(key)
        return handle_backspace if Core::Settings.backspace?(key)
        return unless Core::Settings.printable?(key)

        chars = current_line.grapheme_clusters
        chars.insert(@column, key)
        @lines[@line_index] = chars.join
        @column += 1
      end

      def handle_backspace
        if @column.zero?
          return if @line_index.zero?

          merge_line_up
        else
          chars = current_line.grapheme_clusters
          chars.delete_at(@column - 1)
          @lines[@line_index] = chars.join
          @column -= 1
        end
      end

      def merge_line_up
        return if @line_index.zero?

        current_content = @lines.delete_at(@line_index)
        @line_index -= 1
        prev_length = current_line.grapheme_clusters.length
        @lines[@line_index] = current_line + current_content
        @column = prev_length
      end
    end
  end
end
