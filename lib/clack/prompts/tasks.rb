# frozen_string_literal: true

module Clack
  module Prompts
    # Sequential task runner with spinner animation.
    #
    # Runs tasks in order, showing a spinner while each runs.
    # Displays success/error status after each task completes.
    #
    # Each task is a hash with:
    # - `:title` - display title
    # - `:task` - Proc to execute (exceptions are caught).
    #     Optionally accepts a message-update callable to change
    #     the spinner message mid-execution.
    # - `:enabled` - optional boolean (default true). When false,
    #     the task is skipped entirely.
    #
    # @example Basic usage
    #   results = Clack.tasks(tasks: [
    #     { title: "Checking dependencies", task: -> { check_deps } },
    #     { title: "Building project", task: -> { build } },
    #     { title: "Running tests", task: -> { run_tests } }
    #   ])
    #
    # @example Updating spinner message mid-task
    #   Clack.tasks(tasks: [
    #     { title: "Installing", task: ->(message) {
    #       message.call("Step 1..."); step1
    #       message.call("Step 2..."); step2
    #     }}
    #   ])
    #
    # @example Conditionally skipping tasks
    #   Clack.tasks(tasks: [
    #     { title: "Deploy", task: -> { deploy }, enabled: ENV["DEPLOY"] == "true" }
    #   ])
    #
    # @example Checking results
    #   results.each do |r|
    #     if r.status == :error
    #       puts "#{r.title} failed: #{r.error}"
    #     end
    #   end
    #
    class Tasks
      # A single task definition with title, callable, and enabled flag.
      #
      # @!attribute [r] title
      #   @return [String] the task title
      # @!attribute [r] task
      #   @return [Proc] the task to execute
      # @!attribute [r] enabled
      #   @return [Boolean] whether the task should run (default: true)
      Task = Struct.new(:title, :task, :enabled, keyword_init: true)

      # Result of a completed task, including status and any error.
      #
      # @!attribute [r] title
      #   @return [String] the task title
      # @!attribute [r] status
      #   @return [Symbol] :success or :error
      # @!attribute [r] error
      #   @return [String, nil] error message if failed
      TaskResult = Struct.new(:title, :status, :error, keyword_init: true)

      # @param tasks [Array<Hash>] tasks with :title, :task, and optional :enabled keys
      # @param output [IO] output stream (default: $stdout)
      def initialize(tasks:, output: $stdout)
        @tasks = tasks.map do |task_data|
          Task.new(
            title: task_data[:title],
            task: task_data[:task],
            enabled: task_data.fetch(:enabled, true)
          )
        end
        @output = output
        @results = []
        @current_index = 0
        @frame_index = 0
        @spinning = false
        @spinner_title = nil
        @mutex = Mutex.new
      end

      # Run all tasks sequentially.
      #
      # @return [Array<TaskResult>] results for each task
      def run
        @output.print Core::Cursor.hide
        @tasks.each_with_index do |task, idx|
          next unless task.enabled

          @current_index = idx
          run_task(task)
        end
        @output.print Core::Cursor.show
        @results
      end

      private

      def run_task(task)
        render_pending(task.title)

        begin
          if task.task.arity.zero?
            task.task.call
          else
            task.task.call(method(:update_spinner_message))
          end
          @results << TaskResult.new(title: task.title, status: :success, error: nil)
          render_success(task.title)
        rescue => exception
          @results << TaskResult.new(title: task.title, status: :error, error: exception.message)
          render_error(task.title, exception.message)
        end
      end

      def render_pending(title)
        @mutex.synchronize { @spinner_title = title }
        @output.print "\r#{Core::Cursor.clear_to_end}"
        @output.print "#{Colors.magenta(spinner_frame)}  #{title}"
        @spinner_thread = start_spinner
      end

      def update_spinner_message(new_message)
        @mutex.synchronize { @spinner_title = new_message }
      end

      def render_success(title)
        stop_spinner
        @output.print "\r#{Core::Cursor.clear_to_end}"
        @output.puts "#{Colors.green(Symbols::S_STEP_SUBMIT)}  #{title}"
      end

      def render_error(title, message)
        stop_spinner
        @output.print "\r#{Core::Cursor.clear_to_end}"
        @output.puts "#{Colors.red(Symbols::S_STEP_CANCEL)}  #{title}"
        @output.puts "#{Colors.gray(Symbols::S_BAR)}  #{Colors.red(message)}"
      end

      def start_spinner
        @mutex.synchronize do
          @spinning = true
          @frame_index = 0
        end
        Thread.new do
          while @mutex.synchronize { @spinning }
            frame, title = @mutex.synchronize do
              current_frame = Symbols::SPINNER_FRAMES[@frame_index]
              @frame_index = (@frame_index + 1) % Symbols::SPINNER_FRAMES.length
              [current_frame, @spinner_title]
            end
            @output.print "\r#{Core::Cursor.clear_to_end}"
            @output.print "#{Colors.magenta(frame)}  #{title}"
            sleep Symbols::SPINNER_DELAY
          end
        end
      end

      def stop_spinner
        @mutex.synchronize { @spinning = false }
        @spinner_thread&.join
      end

      def spinner_frame
        @mutex.synchronize { Symbols::SPINNER_FRAMES[@frame_index] }
      end
    end
  end
end
