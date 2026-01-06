# frozen_string_literal: true

module Clack
  module Prompts
    class Progress
      def initialize(total:, message: nil, output: $stdout)
        @total = total
        @current = 0
        @message = message
        @output = output
        @started = false
        @width = 40
      end

      def start(message = nil)
        @message = message if message
        @started = true
        render
        self
      end

      def advance(amount = 1)
        @current = [@current + amount, @total].min
        render
        self
      end

      def update(current)
        @current = [current, @total].min
        render
        self
      end

      def message(msg)
        @message = msg
        render
        self
      end

      def stop(final_message = nil)
        @current = @total
        @message = final_message if final_message
        render_final(:success)
        self
      end

      def error(message = nil)
        @message = message if message
        render_final(:error)
        self
      end

      private

      def render
        return unless @started

        @output.print "\r#{Core::Cursor.clear_to_end}"
        @output.print "#{symbol}  #{progress_bar} #{percentage}#{message_text}"
      end

      def render_final(state)
        @output.print "\r#{Core::Cursor.clear_to_end}"
        sym = (state == :success) ? Colors.green(Symbols::S_STEP_SUBMIT) : Colors.red(Symbols::S_STEP_CANCEL)
        @output.puts "#{sym}  #{@message}"
      end

      def symbol
        Colors.cyan(Symbols::S_STEP_ACTIVE)
      end

      def progress_bar
        filled = @total.zero? ? @width : (@current.to_f / @total * @width).round
        empty = @width - filled
        bar = Colors.green("█" * filled) + Colors.gray("░" * empty)
        "[#{bar}]"
      end

      def percentage
        pct = @total.zero? ? 100 : (@current.to_f / @total * 100).round
        Colors.dim("#{pct.to_s.rjust(3)}%")
      end

      def message_text
        @message ? "  #{@message}" : ""
      end
    end
  end
end
