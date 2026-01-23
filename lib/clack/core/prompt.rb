# frozen_string_literal: true

require "io/console"

module Clack
  module Core
    # Base class for all interactive prompts.
    #
    # Implements a state machine with states: :initial, :active, :error, :submit, :cancel.
    # Subclasses override {#handle_input}, {#build_frame}, and {#build_final_frame}
    # to customize behavior and rendering.
    #
    # The prompt loop:
    # 1. Renders the initial frame
    # 2. Reads keyboard input via {KeyReader}
    # 3. Handles input and transitions state
    # 4. Re-renders the frame
    # 5. Repeats until a terminal state (:submit or :cancel)
    #
    # @abstract Subclass and override {#build_frame} to implement a prompt.
    #
    # @example Creating a custom prompt
    #   class MyPrompt < Clack::Core::Prompt
    #     def build_frame
    #       "#{bar}\n#{symbol_for_state}  #{@message}\n"
    #     end
    #   end
    #
    class Prompt
      # Track active prompts for SIGWINCH notification.
      # Signal handler may fire during register/unregister. We can't use
      # .dup (allocates, forbidden in trap context) so we accept a benign
      # race: worst case, a prompt misses one resize notification.
      @active_prompts = []

      class << self
        attr_reader :active_prompts

        # Register a prompt instance for resize notifications
        def register(prompt)
          @active_prompts << prompt
        end

        def unregister(prompt)
          @active_prompts.delete(prompt)
        end

        # Set up SIGWINCH handler (called once on load).
        # Signal handlers must avoid mutex/complex operations.
        def setup_signal_handler
          return if Clack::Environment.windows?
          return unless Signal.list.key?("WINCH")

          Signal.trap("WINCH") do
            @active_prompts.each(&:request_redraw)
          end
        end
      end

      # @return [Symbol] current state (:initial, :active, :error, :submit, :cancel)
      attr_reader :state
      # @return [Object] the current/final value
      attr_reader :value
      # @return [String, nil] validation error message, if any
      attr_reader :error_message

      # @param message [String] the prompt message to display
      # @param help [String, nil] optional help text shown below the message
      # @param validate [Proc, nil] optional validation proc; returns error string or nil
      # @param transform [Symbol, Proc, nil] transformer (symbol shortcut or proc); applied after validation
      # @param input [IO] input stream (default: $stdin)
      # @param output [IO] output stream (default: $stdout)
      def initialize(message:, help: nil, validate: nil, transform: nil, input: $stdin, output: $stdout)
        @message = message
        @help = help
        @validate = validate
        @transform = Transformers.resolve(transform)
        @input = input
        @output = output
        @state = :initial
        @value = nil
        @error_message = nil
        @prev_frame = nil
        @cursor = 0
        @needs_redraw = false
      end

      # Request a full redraw on next render cycle.
      # Called by SIGWINCH handler when terminal is resized.
      def request_redraw
        @needs_redraw = true
      end

      # Run the prompt interaction loop.
      #
      # Sets up the terminal, renders frames, and processes input until the user
      # submits or cancels. Returns the final value or {Clack::CANCEL}.
      #
      # @return [Object, Clack::CANCEL] the submitted value or CANCEL sentinel
      def run
        Prompt.register(self)
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
        Prompt.unregister(self)
        cleanup_terminal
      end

      protected

      # Process a keypress and update state accordingly.
      # Delegates to {#handle_input} for prompt-specific behavior.
      #
      # @param key [String] the key code from {KeyReader}
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

      # Handle prompt-specific input. Override in subclasses.
      #
      # @param key [String] the raw key code
      # @param action [Symbol, nil] the mapped action (:up, :down, etc.) or nil
      def handle_input(key, action)
        # Override in subclasses
      end

      # Validate and submit the current value.
      # Sets state to :error if validation fails, :submit otherwise.
      # Applies transform after successful validation.
      def submit
        if @validate
          result = @validate.call(@value)
          if result
            @error_message = result.is_a?(Exception) ? result.message : result.to_s
            @state = :error
            return
          end
        end
        if @transform
          begin
            @value = @transform.call(@value)
          rescue => error
            @error_message = "Transform failed: #{error.message}"
            @state = :error
            return
          end
        end
        @state = :submit
      end

      # Render the current frame using differential rendering.
      # Only redraws if the frame content has changed or redraw was requested.
      def render
        frame = build_frame

        # Force redraw if terminal was resized
        if @needs_redraw
          @needs_redraw = false
          @prev_frame = nil
        end

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

      # Build the frame string for the current state.
      # Override in subclasses to customize display.
      #
      # @return [String] the frame content to render
      def build_frame
        # Override in subclasses
        ""
      end

      # Render the final frame after submit/cancel.
      def finalize
        restore_cursor
        @output.print Cursor.clear_down
        @output.print build_final_frame
      end

      # Build the final frame shown after interaction ends.
      # Override to show a different view for completed prompts.
      #
      # @return [String] the final frame content
      def build_final_frame
        build_frame
      end

      # Check if prompt has reached a terminal state.
      #
      # @return [Boolean] true if state is :submit or :cancel
      def terminal_state?
        %i[submit cancel].include?(@state)
      end

      private

      def setup_terminal
        @output.print Cursor.hide
      end

      def cleanup_terminal
        @output.print Cursor.show
      rescue IOError, SystemCallError
        # Output unavailable - terminal may need manual reset
      end

      def restore_cursor
        return unless @prev_frame

        lines = @prev_frame.count("\n")
        @output.print Cursor.up(lines) if lines.positive?
        @output.print Cursor.column(1)
      end

      def bar
        Colors.gray(Symbols::S_BAR)
      end

      def active_bar
        (@state == :error) ? Colors.yellow(Symbols::S_BAR) : bar
      end

      def bar_end
        (@state == :error) ? Colors.yellow(Symbols::S_BAR_END) : Colors.gray(Symbols::S_BAR_END)
      end

      def help_line
        return "" unless @help

        "#{bar}  #{Colors.dim(@help)}\n"
      end

      def cursor_block
        Colors.inverse(" ")
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
