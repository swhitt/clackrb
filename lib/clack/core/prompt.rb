require "io/console"

module Clack
  module Core
    class Prompt
      STATES = %i[initial active cancel submit error].freeze

      attr_reader :state, :value, :error_message

      def initialize(message:, validate: nil, input: $stdin, output: $stdout)
        @message = message
        @validate = validate
        @input = input
        @output = output
        @state = :initial
        @value = nil
        @error_message = nil
        @prev_frame = nil
        @cursor = 0
      end

      def run
        setup_terminal
        render
        @state = :active

        loop do
          key = KeyReader.read
          handle_key(key)
          render

          break if terminal_state?
        end

        finalize
        (terminal_state? && @state == :cancel) ? CANCEL : @value
      ensure
        cleanup_terminal
      end

      protected

      def handle_key(key)
        return if terminal_state?

        @state = :active if @state == :error

        action = Settings.action?(key)

        case action
        when :cancel
          @state = :cancel
        when :enter
          submit
        else
          handle_input(key, action)
        end
      end

      def handle_input(key, action)
        # Override in subclasses
      end

      def submit
        if @validate
          result = @validate.call(@value)
          if result
            @error_message = result.is_a?(Exception) ? result.message : result.to_s
            @state = :error
            return
          end
        end
        @state = :submit
      end

      def render
        frame = build_frame
        return if frame == @prev_frame

        if @state == :initial
          @output.print Cursor.hide
        else
          restore_cursor
        end

        @output.print Cursor.clear_down
        @output.print frame
        @prev_frame = frame
      end

      def build_frame
        # Override in subclasses
        ""
      end

      def finalize
        restore_cursor
        @output.print Cursor.clear_down
        @output.print build_final_frame
        @output.print "\n"
      end

      def build_final_frame
        build_frame
      end

      def terminal_state?
        %i[submit cancel].include?(@state)
      end

      private

      def setup_terminal
        @output.print Cursor.hide
      end

      def cleanup_terminal
        @output.print Cursor.show
      end

      def restore_cursor
        return unless @prev_frame

        lines = @prev_frame.count("\n")
        @output.print Cursor.up(lines) if lines > 0
        @output.print Cursor.column(1)
      end

      def bar(color = :gray)
        Colors.send(color, Symbols::S_BAR)
      end

      def symbol_for_state
        case @state
        when :initial, :active then Colors.cyan(Symbols::S_STEP_ACTIVE)
        when :submit then Colors.green(Symbols::S_STEP_SUBMIT)
        when :cancel then Colors.red(Symbols::S_STEP_CANCEL)
        when :error then Colors.yellow(Symbols::S_STEP_ERROR)
        end
      end
    end
  end
end
