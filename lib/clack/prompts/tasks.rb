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
    # - `:task` - Proc to execute (exceptions are caught)
    #
    # @example Basic usage
    #   results = Clack.tasks(tasks: [
    #     { title: "Checking dependencies", task: -> { check_deps } },
    #     { title: "Building project", task: -> { build } },
    #     { title: "Running tests", task: -> { run_tests } }
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
      # @!attribute [r] title
      #   @return [String] the task title
      # @!attribute [r] task
      #   @return [Proc] the task to execute
      Task = Struct.new(:title, :task, keyword_init: true)

      # @!attribute [r] title
      #   @return [String] the task title
      # @!attribute [r] status
      #   @return [Symbol] :success or :error
      # @!attribute [r] error
      #   @return [String, nil] error message if failed
      TaskResult = Struct.new(:title, :status, :error, keyword_init: true)

      # @param tasks [Array<Hash>] tasks with :title and :task keys
      # @param output [IO] output stream (default: $stdout)
      def initialize(tasks:, output: $stdout)
        @tasks = tasks.map { |task_data| Task.new(title: task_data[:title], task: task_data[:task]) }
        @output = output
        @results = []
        @current_index = 0
        @frame_index = 0
        @spinning = false
        @mutex = Mutex.new
      end

      # Run all tasks sequentially.
      #
      # @return [Array<TaskResult>] results for each task
      def run
        @output.print Core::Cursor.hide
        @tasks.each_with_index do |task, idx|
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
          task.task.call
          @results << TaskResult.new(title: task.title, status: :success, error: nil)
          render_success(task.title)
        rescue => exception
          @results << TaskResult.new(title: task.title, status: :error, error: exception.message)
          render_error(task.title, exception.message)
        end
      end

      def render_pending(title)
        @output.print "\r#{Core::Cursor.clear_to_end}"
        @output.print "#{Colors.magenta(spinner_frame)}  #{title}"
        @spinner_thread = start_spinner(title)
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

      def start_spinner(title)
        @mutex.synchronize do
          @spinning = true
          @frame_index = 0
        end
        Thread.new do
          while @mutex.synchronize { @spinning }
            frame = @mutex.synchronize do
              current_frame = Symbols::SPINNER_FRAMES[@frame_index]
              @frame_index = (@frame_index + 1) % Symbols::SPINNER_FRAMES.length
              current_frame
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
