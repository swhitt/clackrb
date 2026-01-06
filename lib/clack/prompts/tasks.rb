# frozen_string_literal: true

module Clack
  module Prompts
    class Tasks
      Task = Struct.new(:title, :task, keyword_init: true)
      TaskResult = Struct.new(:title, :status, :error, keyword_init: true)

      def initialize(tasks:, output: $stdout)
        @tasks = tasks.map { |task_data| Task.new(title: task_data[:title], task: task_data[:task]) }
        @output = output
        @results = []
        @current_index = 0
        @frame_index = 0
        @spinning = false
      end

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
        @output.print "#{Colors.cyan(spinner_frame)}  #{title}"
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
        @spinning = true
        @frame_index = 0
        Thread.new do
          while @spinning
            @output.print "\r#{Core::Cursor.clear_to_end}"
            @output.print "#{Colors.cyan(spinner_frame)}  #{title}"
            @frame_index = (@frame_index + 1) % Symbols::SPINNER_FRAMES.length
            sleep Symbols::SPINNER_DELAY
          end
        end
      end

      def stop_spinner
        @spinning = false
        @spinner_thread&.join
      end

      def spinner_frame
        Symbols::SPINNER_FRAMES[@frame_index]
      end
    end
  end
end
