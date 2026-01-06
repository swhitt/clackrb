# frozen_string_literal: true

module Clack
  # A streaming log that clears on success and remains on failure
  # Useful for build output, npm install style streaming, etc.
  #
  # @example Basic usage
  #   tl = Clack.task_log(title: "Building...")
  #   tl.message("Compiling file 1...")
  #   tl.message("Compiling file 2...")
  #   tl.success("Build complete!")  # Clears the log
  #   # or tl.error("Build failed!") # Keeps the log visible
  #
  class TaskLog
    # @param title [String] Title displayed at the top
    # @param limit [Integer, nil] Max lines to show (older lines scroll out)
    # @param retain_log [Boolean] Keep full log history for display on error
    # @param output [IO] Output stream
    def initialize(title:, limit: nil, retain_log: false, output: $stdout)
      @title = title
      @limit = limit
      @retain_log = retain_log
      @output = output
      @buffer = []
      @full_buffer = []
      @groups = []
      @lines_written = 0
      @tty = tty_output?(output)

      render_title
    end

    # Add a message to the log
    # @param msg [String] Message to display
    # @param raw [Boolean] If true, don't add newline between messages
    def message(msg, raw: false)
      clear_buffer
      @buffer << msg.to_s.gsub(/\e\[[\d;]*[ABCDEFGHfJKSTsu]/, "") # Strip cursor movement codes
      apply_limit
      render_buffer if @tty
    end

    # Create a named group for messages
    # @param name [String] Group header name
    # @return [TaskLogGroup] Group object with message/success/error methods
    def group(name)
      grp = TaskLogGroup.new(name, self)
      @groups << grp
      grp
    end

    # Complete with success - clears the log
    # @param msg [String] Success message
    # @param show_log [Boolean] If true, show the log even on success
    def success(msg, show_log: false)
      clear_all
      @output.puts "#{Colors.green(Symbols::S_STEP_SUBMIT)}  #{msg}"
      render_full_buffer if show_log
      reset_buffers
    end

    # Complete with error - keeps the log visible
    # @param msg [String] Error message
    # @param show_log [Boolean] If false, hide the log
    def error(msg, show_log: true)
      clear_all
      @output.puts "#{Colors.red(Symbols::S_STEP_ERROR)}  #{msg}"
      render_full_buffer if show_log
      reset_buffers
    end

    # @api private
    def add_group_message(_group, msg)
      clear_buffer
      @buffer << msg.to_s
      apply_limit
      render_buffer if @tty
    end

    private

    def render_title
      @output.puts Colors.gray(Symbols::S_BAR)
      @output.puts "#{Colors.green(Symbols::S_STEP_SUBMIT)}  #{@title}"
      @output.puts Colors.gray(Symbols::S_BAR)
      @lines_written = 3
    end

    def clear_buffer
      return unless @tty && @lines_written.positive?

      # Move up and clear the buffer lines (not the title)
      buffer_lines = @buffer.sum { |line| line.lines.count }
      return unless buffer_lines.positive?

      @output.print "\e[#{buffer_lines}A" # Move up
      @output.print "\e[J" # Clear to end
    end

    def clear_all
      return unless @tty && @lines_written.positive?

      total_lines = @lines_written + @buffer.sum { |line| line.lines.count }
      @output.print "\e[#{total_lines}A" # Move up
      @output.print "\e[J" # Clear to end
    end

    def render_buffer
      bar = Colors.gray(Symbols::S_BAR)
      @buffer.each do |message|
        print_message_lines(bar, message)
      end
    end

    def render_full_buffer
      bar = Colors.gray(Symbols::S_BAR)
      lines = @retain_log ? (@full_buffer + @buffer) : @buffer
      lines.each do |message|
        print_message_lines(bar, message)
      end
    end

    def print_message_lines(bar, message)
      message.each_line do |line|
        @output.puts "#{bar}  #{Colors.dim(line.chomp)}"
      end
    end

    def tty_output?(output)
      output.tty?
    rescue NoMethodError
      false
    end

    def apply_limit
      return unless @limit && @buffer.length > @limit

      overflow = @buffer.shift(@buffer.length - @limit)
      @full_buffer.concat(overflow) if @retain_log
    end

    def reset_buffers
      @buffer.clear
      @full_buffer.clear
      @groups.clear
      @lines_written = 0
    end
  end

  # A group within a TaskLog
  class TaskLogGroup
    def initialize(name, parent)
      @name = name
      @parent = parent
      @buffer = []
    end

    # Add a message to this group
    def message(msg, raw: false)
      @buffer << msg.to_s
      @parent.add_group_message(self, msg)
    end

    # Complete group with success
    def success(msg)
      @parent.add_group_message(self, "#{Colors.green("✓")} #{msg}")
    end

    # Complete group with error
    def error(msg)
      @parent.add_group_message(self, "#{Colors.red("✗")} #{msg}")
    end
  end
end
