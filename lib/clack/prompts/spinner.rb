# frozen_string_literal: true

module Clack
  module Prompts
    # Animated spinner for async operations.
    #
    # Runs animation in a background thread. Call {#start} to begin,
    # {#stop}/{#error}/{#cancel} to finish. Thread-safe message updates.
    #
    # Indicator modes:
    # - `:dots` - animating dots after message (default)
    # - `:timer` - elapsed time display [Xs] or [Xm Ys]
    #
    # @example Basic usage
    #   s = Clack.spinner
    #   s.start("Installing...")
    #   # ... do work ...
    #   s.stop("Done!")
    #
    # @example With timer
    #   s = Clack.spinner(indicator: :timer)
    #   s.start("Building")
    #   build_project
    #   s.stop("Build complete")  # => "Build complete [12s]"
    #
    # @example Updating message mid-spin
    #   s = Clack.spinner
    #   s.start("Step 1...")
    #   do_step_1
    #   s.message("Step 2...")
    #   do_step_2
    #   s.stop("All done!")
    #
    class Spinner
      # @param indicator [:dots, :timer] animation style (default: :dots)
      # @param frames [Array<String>, nil] custom spinner frames
      # @param delay [Float, nil] delay between frames in seconds
      # @param style_frame [Proc, nil] proc to style each frame character
      # @param output [IO] output stream (default: $stdout)
      def initialize(
        indicator: :dots,
        frames: nil,
        delay: nil,
        style_frame: nil,
        output: $stdout
      )
        @output = output
        @indicator = indicator
        @frames = frames || Symbols::SPINNER_FRAMES
        @delay = delay || Symbols::SPINNER_DELAY
        @style_frame = style_frame || ->(frame) { Colors.magenta(frame) }
        @running = false
        @cancelled = false
        @message = ""
        @thread = nil
        @frame_idx = 0
        @dot_idx = 0
        @prev_frame = nil
        @start_time = nil
        @mutex = Mutex.new
      end

      # Start the spinner animation.
      #
      # @param message [String, nil] initial message to display
      # @return [self] for method chaining
      def start(message = nil)
        @mutex.synchronize do
          return if @running

          @message = remove_trailing_dots(message || "")
          @running = true
          @cancelled = false
          @prev_frame = nil
          @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          @dot_idx = 0
        end

        @output.print Core::Cursor.hide
        @output.print "#{Colors.gray(Symbols::S_BAR)}\n"

        @thread = Thread.new { spin_loop }
        self
      end

      # Stop with success state.
      #
      # @param message [String, nil] final message (uses current if nil)
      def stop(message = nil)
        finish(:success, message)
      end

      # Stop with error state.
      #
      # @param message [String, nil] error message (uses current if nil)
      def error(message = nil)
        finish(:error, message)
      end

      # Stop with cancelled state.
      #
      # @param message [String, nil] cancellation message
      def cancel(message = nil)
        finish(:cancel, message)
      end

      # Update the spinner message while running.
      #
      # @param msg [String] new message to display
      def message(msg)
        @mutex.synchronize { @message = remove_trailing_dots(msg) }
      end

      # Clear the spinner without showing a final message.
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

      def remove_trailing_dots(msg)
        msg.to_s.sub(/\.+$/, "")
      end

      def format_timer
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time
        min = (elapsed / 60).to_i
        secs = (elapsed % 60).to_i
        min.positive? ? "[#{min}m #{secs}s]" : "[#{secs}s]"
      end

      def spin_loop
        frame_count = 0
        while @mutex.synchronize { @running }
          frame = @style_frame.call(@frames[@frame_idx])
          msg = @mutex.synchronize { @message }
          render_frame(frame, msg, frame_count)

          @frame_idx = (@frame_idx + 1) % @frames.length
          frame_count += 1
          sleep @delay
        end
      end

      def render_frame(frame, msg, frame_count)
        suffix = case @indicator
        when :timer
          " #{format_timer}"
        when :dots
          # Animate dots: cycles every 8 frames (0-3 dots)
          dot_count = (frame_count / 2) % 4
          "." * dot_count
        else
          ""
        end

        line = "#{frame}  #{msg}#{suffix}"
        @mutex.synchronize do
          return if line == @prev_frame

          @output.print "\r#{Core::Cursor.clear_to_end}#{line}"
          @prev_frame = line
        end
      end

      def finish(state, message)
        msg, timer_suffix = @mutex.synchronize do
          @running = false
          suffix = (@indicator == :timer) ? " #{format_timer}" : ""
          [message || @message, suffix]
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

        @output.print "#{symbol}  #{msg}#{timer_suffix}\n"
        @output.print Core::Cursor.show
      end

      def restore_cursor
        return unless @prev_frame

        @output.print "\r"
      end
    end
  end
end
