module Clack
  module Prompts
    class Spinner
      def initialize(output: $stdout)
        @output = output
        @running = false
        @cancelled = false
        @message = ""
        @thread = nil
        @frame_idx = 0
        @prev_frame = nil
        @mutex = Mutex.new
      end

      def start(message = nil)
        @mutex.synchronize do
          return if @running

          @message = message || ""
          @running = true
          @cancelled = false
          @prev_frame = nil
        end

        @output.print Core::Cursor.hide
        @output.print "#{Colors.gray(Symbols::S_BAR)}\n"

        @thread = Thread.new { spin_loop }
        self
      end

      def stop(message = nil)
        finish(:success, message)
      end

      def error(message = nil)
        finish(:error, message)
      end

      def cancel(message = nil)
        finish(:cancel, message)
      end

      def message(msg)
        @mutex.synchronize { @message = msg }
      end

      def clear
        @mutex.synchronize do
          @running = false
        end
        @thread&.join
        restore_cursor
        @output.print Core::Cursor.clear_down
        @output.print Core::Cursor.show
      end

      def cancelled?
        @cancelled
      end

      private

      def spin_loop
        while @mutex.synchronize { @running }
          frame = Symbols::SPINNER_FRAMES[@frame_idx]
          msg = @mutex.synchronize { @message }
          render_frame(frame, msg)

          @frame_idx = (@frame_idx + 1) % Symbols::SPINNER_FRAMES.length
          sleep Symbols::SPINNER_DELAY
        end
      end

      def render_frame(frame, msg)
        line = "#{Colors.magenta(frame)}  #{msg}"
        return if line == @prev_frame

        @output.print "\r#{Core::Cursor.clear_to_end}#{line}"
        @prev_frame = line
      end

      def finish(state, message)
        msg = @mutex.synchronize do
          @running = false
          message || @message
        end

        @thread&.join

        @output.print "\r#{Core::Cursor.clear_to_end}"

        symbol = case state
        when :success then Colors.green(Symbols::S_STEP_SUBMIT)
        when :error then Colors.red(Symbols::S_STEP_ERROR)
        when :cancel
          @cancelled = true
          Colors.red(Symbols::S_STEP_CANCEL)
        end

        @output.print "#{symbol}  #{msg}\n"
        @output.print Core::Cursor.show
      end

      def restore_cursor
        return unless @prev_frame
        @output.print "\r"
      end
    end
  end
end
