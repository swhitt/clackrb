# frozen_string_literal: true

module Clack
  module Prompts
    # Sequential task runner with spinner animation.
    #
    # Runs tasks in order, showing a spinner while each runs.
    # Displays success/error status after each task completes.
    #
    # Each task is a hash with:
    # - +:title+ - display title
    # - +:task+ - Proc to execute (exceptions are caught).
    #     Optionally accepts a message-update callable to change
    #     the spinner message mid-execution.
    # - +:enabled+ - optional boolean (default true). When false,
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
      Task = Data.define(:title, :task, :enabled)

      # Result of a completed task, including status and any error.
      #
      # @!attribute [r] title
      #   @return [String] the task title
      # @!attribute [r] status
      #   @return [Symbol] :success or :error
      # @!attribute [r] error
      #   @return [String, nil] error message if failed
      TaskResult = Data.define(:title, :status, :error)

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
      end

      # Run all tasks sequentially.
      #
      # @return [Array<TaskResult>] results for each task
      def run
        @output.print Core::Cursor.hide
        @tasks.each do |task|
          next unless task.enabled

          run_task(task)
        end
        @output.print Core::Cursor.show
        @results
      end

      private

      def run_task(task)
        spinner = Spinner.new(output: @output)
        spinner.start(task.title)

        begin
          if task.task.arity.zero?
            task.task.call
          else
            task.task.call(spinner.method(:message))
          end
          spinner.stop(task.title)
          @results << TaskResult.new(title: task.title, status: :success, error: nil)
        rescue => exception
          spinner.error(task.title)
          @output.puts "#{Colors.gray(Symbols::S_BAR)}  #{Colors.red(exception.message)}"
          @results << TaskResult.new(title: task.title, status: :error, error: exception.message)
        end
      end
    end
  end
end
