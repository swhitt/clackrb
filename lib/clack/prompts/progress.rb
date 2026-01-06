# frozen_string_literal: true

module Clack
  module Prompts
    # Visual progress bar for measurable operations.
    #
    # Shows a filled/empty bar with percentage. Call {#start} to begin,
    # {#advance} or {#update} to show progress, {#stop} to complete.
    #
    # @example Basic usage
    #   progress = Clack.progress(total: 100, message: "Downloading...")
    #   progress.start
    #   100.times { |i| progress.update(i + 1) }
    #   progress.stop("Download complete!")
    #
    # @example With advance
    #   progress = Clack.progress(total: files.size)
    #   progress.start("Processing files")
    #   files.each do |file|
    #     process(file)
    #     progress.advance  # increments by 1
    #   end
    #   progress.stop("Done!")
    #
    class Progress
      # @param total [Integer] total number of steps (must be non-negative)
      # @param message [String, nil] initial message to display
      # @param output [IO] output stream (default: $stdout)
      # @raise [ArgumentError] if total is negative
      def initialize(total:, message: nil, output: $stdout)
        raise ArgumentError, "total must be non-negative" if total.negative?

        @total = total
        @current = 0
        @message = message
        @output = output
        @started = false
        @width = 40
      end

      # Start displaying the progress bar.
      #
      # @param message [String, nil] optional message to display
      # @return [self] for method chaining
      def start(message = nil)
        @message = message if message
        @started = true
        render
        self
      end

      # Advance progress by the given amount.
      #
      # @param amount [Integer] steps to advance (default: 1)
      # @return [self] for method chaining
      def advance(amount = 1)
        @current = [@current + amount, @total].min
        render
        self
      end

      # Set progress to an absolute value.
      #
      # @param current [Integer] current progress value
      # @return [self] for method chaining
      def update(current)
        @current = [current, @total].min
        render
        self
      end

      # Update the message without changing progress.
      #
      # @param msg [String] new message
      # @return [self] for method chaining
      def message(msg)
        @message = msg
        render
        self
      end

      # Complete with success. Sets progress to 100%.
      #
      # @param final_message [String, nil] final message to display
      # @return [self] for method chaining
      def stop(final_message = nil)
        @current = @total
        @message = final_message if final_message
        render_final(:success)
        self
      end

      # Complete with error state.
      #
      # @param message [String, nil] error message
      # @return [self] for method chaining
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
        bar = Colors.green(Symbols::S_PROGRESS_FILLED * filled) + Colors.gray(Symbols::S_PROGRESS_EMPTY * empty)
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
