# frozen_string_literal: true

require_relative "clack/version"
require_relative "clack/symbols"
require_relative "clack/colors"
require_relative "clack/environment"
require_relative "clack/utils"
require_relative "clack/core/cursor"
require_relative "clack/core/settings"
require_relative "clack/core/key_reader"
require_relative "clack/core/prompt"
require_relative "clack/core/options_helper"
require_relative "clack/core/text_input_helper"
require_relative "clack/prompts/text"
require_relative "clack/prompts/multiline_text"
require_relative "clack/prompts/password"
require_relative "clack/prompts/confirm"
require_relative "clack/prompts/select"
require_relative "clack/prompts/multiselect"
require_relative "clack/prompts/spinner"
require_relative "clack/prompts/autocomplete"
require_relative "clack/prompts/autocomplete_multiselect"
require_relative "clack/prompts/path"
require_relative "clack/prompts/progress"
require_relative "clack/prompts/select_key"
require_relative "clack/prompts/tasks"
require_relative "clack/prompts/group_multiselect"
require_relative "clack/prompts/date"
require_relative "clack/log"
require_relative "clack/note"
require_relative "clack/box"
require_relative "clack/group"
require_relative "clack/stream"
require_relative "clack/task_log"
require_relative "clack/validators"
require_relative "clack/transformers"

# Clack - Beautiful CLI prompts for Ruby
#
# A faithful Ruby port of @clack/prompts, bringing delightful terminal
# aesthetics to your Ruby projects.
#
# @example Basic usage
#   Clack.intro "Welcome to my-app"
#   name = Clack.text(message: "What's your name?")
#   exit 1 if Clack.cancel?(name)
#   Clack.outro "Nice to meet you, #{name}!"
#
# @example Using prompt groups
#   result = Clack.group do |g|
#     g.prompt(:name) { Clack.text(message: "Name?") }
#     g.prompt(:confirm) { Clack.confirm(message: "Continue?") }
#   end
#
# @see https://github.com/bombshell-dev/clack Original JavaScript library
module Clack
  # Sentinel value returned when user cancels a prompt (Escape or Ctrl+C)
  CANCEL = Object.new.tap { |o| o.define_singleton_method(:inspect) { "Clack::CANCEL" } }.freeze

  # Warning result from validation - allows user to proceed with confirmation.
  # Validators can return a Warning to show a yellow message that doesn't block
  # submission if the user confirms by pressing Enter again.
  #
  # @example Validator returning a warning
  #   validate: ->(v) { Clack::Warning.new("File exists, overwrite?") if File.exist?(v) }
  Warning = Data.define(:message) do
    # @return [String] the warning message
    def to_s = message
  end

  class << self
    # Create a validation warning that allows the user to proceed with confirmation.
    #
    # @param message [String] the warning message
    # @return [Warning] a warning object
    #
    # @example
    #   validate: ->(v) { Clack.warning("Unusual value") if v.length > 100 }
    def warning(message)
      Warning.new(message)
    end

    # Check if a prompt result was cancelled by the user.
    #
    # @param value [Object] the result from a prompt
    # @return [Boolean] true if the user cancelled
    def cancel?(value)
      value.equal?(CANCEL)
    end
    alias_method :cancelled?, :cancel?

    # Check if cancelled and show cancel message if so.
    # Useful for guard clauses in CLI scripts.
    #
    # @param value [Object] the result from a prompt
    # @param message [String] message to display if cancelled
    # @param output [IO] output stream
    # @return [Boolean] true if cancelled
    #
    # @example Guard clause pattern
    #   name = Clack.text(message: "Name?")
    #   return if Clack.handle_cancel(name)  # Shows "Cancelled" and returns true
    #
    # @example With custom message
    #   return if Clack.handle_cancel(name, "Aborted by user")
    def handle_cancel(value, message = "Cancelled", output: $stdout)
      return false unless cancel?(value)

      cancel(message, output: output)
      true
    end

    # Display an intro banner at the start of a CLI session.
    #
    # @param title [String, nil] optional title text
    # @param output [IO] output stream (default: $stdout)
    # @return [void]
    def intro(title = nil, output: $stdout)
      output.puts "#{Colors.gray(Symbols::S_BAR_START)}  #{title}"
    end

    # Display an outro banner at the end of a CLI session.
    #
    # @param message [String, nil] optional closing message
    # @param output [IO] output stream (default: $stdout)
    # @return [void]
    def outro(message = nil, output: $stdout)
      output.puts Colors.gray(Symbols::S_BAR)
      output.puts "#{Colors.gray(Symbols::S_BAR_END)}  #{message}"
      output.puts
    end

    # Display a cancellation message (typically after user presses Escape).
    #
    # @param message [String, nil] optional cancellation message
    # @param output [IO] output stream (default: $stdout)
    # @return [void]
    def cancel(message = nil, output: $stdout)
      output.puts Colors.gray(Symbols::S_BAR)
      output.puts "#{Colors.gray(Symbols::S_BAR_END)}  #{Colors.red(message)}"
      output.puts
    end

    # Prompt for single-line text input.
    #
    # @param message [String] the prompt message
    # @option opts [String, nil] :placeholder dim text shown when input is empty
    # @option opts [String, nil] :default_value value used if submitted empty
    # @option opts [String, nil] :initial_value pre-filled editable text
    # @option opts [Proc, nil] :validate validation function returning error string, Warning, or nil
    # @option opts [Symbol, Proc, nil] :transform transform function to normalize the value
    # @option opts [String, nil] :help help text shown below the message
    # @return [String, CANCEL] user input or CANCEL if cancelled
    def text(message:, **opts)
      Prompts::Text.new(message:, **opts).run
    end

    # Prompt for multi-line text input.
    #
    # Enter inserts a newline, Ctrl+D submits. Useful for commit messages,
    # notes, or any multi-line content.
    #
    # @param message [String] the prompt message
    # @option opts [String, nil] :initial_value pre-filled editable text (can contain newlines)
    # @option opts [Proc, nil] :validate validation function returning error string, Warning, or nil
    # @option opts [String, nil] :help help text shown below the message
    # @return [String, CANCEL] user input (lines joined with \n) or CANCEL if cancelled
    def multiline_text(message:, **opts)
      Prompts::MultilineText.new(message:, **opts).run
    end

    # Prompt for password input (masked display).
    #
    # @param message [String] the prompt message
    # @option opts [String] :mask character to display for each input character (default: ▪)
    # @option opts [Proc, nil] :validate validation function returning error string, Warning, or nil
    # @option opts [String, nil] :help help text shown below the message
    # @return [String, CANCEL] password or CANCEL if cancelled
    def password(message:, **opts)
      Prompts::Password.new(message:, **opts).run
    end

    # Prompt for yes/no confirmation.
    #
    # @param message [String] the prompt message
    # @option opts [String] :active label for "yes" option (default: "Yes")
    # @option opts [String] :inactive label for "no" option (default: "No")
    # @option opts [Boolean] :initial_value default selection (default: true)
    # @return [Boolean, CANCEL] true/false or CANCEL if cancelled
    def confirm(message:, **opts)
      Prompts::Confirm.new(message:, **opts).run
    end

    # Prompt to select one option from a list.
    #
    # @param message [String] the prompt message
    # @param options [Array<Hash, String>] list of options
    # @option opts [Object, nil] :initial_value value of initially selected option
    # @option opts [Integer, nil] :max_items max visible items (enables scrolling)
    # @return [Object, CANCEL] selected value or CANCEL if cancelled
    def select(message:, options:, **opts)
      Prompts::Select.new(message:, options: options, **opts).run
    end

    # Prompt to select multiple options from a list.
    #
    # @param message [String] the prompt message
    # @param options [Array<Hash, String>] list of options
    # @option opts [Array, nil] :initial_values initially selected values
    # @option opts [Boolean] :required require at least one selection (default: true)
    # @option opts [Integer, nil] :max_items max visible items (enables scrolling)
    # @return [Array, CANCEL] selected values or CANCEL if cancelled
    def multiselect(message:, options:, **opts)
      Prompts::Multiselect.new(message:, options: options, **opts).run
    end

    # Create an animated spinner for async operations.
    #
    # @return [Prompts::Spinner] spinner instance (call #start, #stop, #error)
    def spinner(**opts)
      Prompts::Spinner.new(**opts)
    end

    # Run a block with a spinner, handling success/error automatically.
    #
    # @param message [String] initial spinner message
    # @param success [String, nil] message on success (defaults to message)
    # @param error [String, nil] message on error (defaults to exception message)
    # @return [Object] the block's return value
    # @raise [Exception] re-raises any exception from the block
    #
    # @example Basic usage
    #   result = Clack.spin("Installing dependencies...") { system("npm install") }
    #
    # @example With custom success message
    #   Clack.spin("Compiling...", success: "Build complete!") { build_project }
    #
    # @example Access spinner inside block
    #   Clack.spin("Working...") do |s|
    #     s.message "Step 1..."
    #     do_step_1
    #     s.message "Step 2..."
    #     do_step_2
    #   end
    def spin(message, success: nil, error: nil, **opts)
      s = spinner(**opts)
      s.start(message)
      begin
        result = yield(s)
        s.stop(success || message)
        result
      rescue => exception
        s.error(error || exception.message)
        raise
      end
    end

    # Prompt with type-to-filter autocomplete.
    #
    # @param message [String] the prompt message
    # @param options [Array<Hash, String>] list of options to filter
    # @option opts [String, nil] :placeholder placeholder text
    # @option opts [Proc, nil] :filter custom filter proc receiving (option_hash, query_string)
    #   and returning true/false. Defaults to case-insensitive substring match
    #   across label, value, and hint.
    # @return [Object, CANCEL] selected value or CANCEL if cancelled
    def autocomplete(message:, options:, **opts)
      Prompts::Autocomplete.new(message:, options: options, **opts).run
    end

    # Prompt with type-to-filter autocomplete and multiselect.
    #
    # @param message [String] the prompt message
    # @param options [Array<Hash, String>] list of options to filter
    # @option opts [String, nil] :placeholder placeholder text
    # @option opts [Boolean] :required require at least one selection (default: true)
    # @option opts [Array, nil] :initial_values initially selected values
    # @return [Array, CANCEL] selected values or CANCEL if cancelled
    def autocomplete_multiselect(message:, options:, **opts)
      Prompts::AutocompleteMultiselect.new(message:, options: options, **opts).run
    end

    # Prompt for file/directory path with filesystem navigation.
    #
    # @param message [String] the prompt message
    # @option opts [String] :root starting directory (default: ".")
    # @option opts [Boolean] :only_directories only show directories (default: false)
    # @return [String, CANCEL] selected path or CANCEL if cancelled
    def path(message:, **opts)
      Prompts::Path.new(message:, **opts).run
    end

    # Create a progress bar for measurable operations.
    #
    # @param total [Integer] total number of steps
    # @option opts [String, nil] :message optional message
    # @return [Prompts::Progress] progress instance (call #start, #advance, #stop)
    def progress(total:, **opts)
      Prompts::Progress.new(total: total, **opts)
    end

    # Prompt to select an option by pressing a key.
    #
    # @param message [String] the prompt message
    # @param options [Array<Hash>] options with :value, :label, and :key
    # @return [Object, CANCEL] selected value or CANCEL if cancelled
    def select_key(message:, options:, **opts)
      Prompts::SelectKey.new(message:, options: options, **opts).run
    end

    # Run multiple tasks with progress indicators.
    #
    # @param tasks [Array<Hash>] tasks with :title and :task (Proc)
    # @return [Array<Hash>] task results
    def tasks(tasks:, **opts)
      Prompts::Tasks.new(tasks: tasks, **opts).run
    end

    # Prompt to select multiple options organized in groups.
    #
    # @param message [String] the prompt message
    # @param options [Array<Hash>] groups with :label and :options
    # @option opts [Array, nil] :initial_values initially selected values
    # @option opts [Boolean] :required require at least one selection (default: true)
    # @return [Array, CANCEL] selected values or CANCEL if cancelled
    def group_multiselect(message:, options:, **opts)
      Prompts::GroupMultiselect.new(message:, options: options, **opts).run
    end

    # Prompt for date selection with inline segmented input.
    #
    # Navigate between segments with Tab/arrow keys, adjust with up/down,
    # or type digits directly.
    #
    # @param message [String] the prompt message
    # @option opts [Symbol] :format date format (:iso, :us, :eu)
    # @option opts [Date, Time, String, nil] :initial_value initial date value (default: today)
    # @option opts [Date, nil] :min minimum allowed date
    # @option opts [Date, nil] :max maximum allowed date
    # @option opts [Proc, nil] :validate custom validation proc
    # @option opts [String, nil] :help help text shown below the message
    # @return [Date, CANCEL] selected date or CANCEL if cancelled
    def date(message:, **opts)
      Prompts::Date.new(message:, **opts).run
    end

    # Access the Log module for styled console output.
    #
    # @return [Module] the Log module
    def log
      Log
    end

    # Access the Stream module for streaming output.
    #
    # @return [Module] the Stream module
    def stream
      Stream
    end

    # Display a note box with optional title.
    #
    # @param message [String] the note content
    # @param title [String, nil] optional title
    # @return [void]
    def note(message = "", title: nil, **opts)
      Note.render(message, title: title, **opts)
    end

    # Display content in a customizable box.
    #
    # @param message [String] the box content
    # @param title [String, nil] optional title
    # @option opts [:left, :center, :right] :content_align content alignment
    # @option opts [:left, :center, :right] :title_align title alignment
    # @option opts [Integer, :auto] :width box width
    # @option opts [Boolean] :rounded use rounded corners
    # @return [void]
    def box(message = "", title: "", **opts)
      Box.render(message, title: title, **opts)
    end

    # Create a streaming task log that clears on success, shows on error.
    # Useful for build output, npm install style streaming, etc.
    #
    # @param title [String] title displayed at the top
    # @option opts [Integer, nil] :limit max lines to show (older lines scroll out)
    # @option opts [Boolean] :retain_log keep full log history for display on error
    # @return [TaskLog] task log instance
    def task_log(title:, **opts)
      TaskLog.new(title: title, **opts)
    end

    # Access global settings
    # @return [Hash] Current configuration
    # @see Core::Settings.update for modifying settings
    def settings
      Core::Settings.config
    end

    # Update global settings
    # @option opts [Hash, nil] :aliases Custom key to action mappings
    # @option opts [Boolean, nil] :with_guide Whether to show guide bars
    # @return [Hash] Updated configuration
    #
    # @example Custom key bindings
    #   Clack.update_settings(aliases: { "y" => :enter, "n" => :cancel })
    #
    # @example Disable guide bars
    #   Clack.update_settings(with_guide: false)
    def update_settings(**opts)
      Core::Settings.update(**opts)
    end

    # Check if running in a CI environment
    # @return [Boolean]
    def ci?
      Environment.ci?
    end

    # Check if running on Windows
    # @return [Boolean]
    def windows?
      Environment.windows?
    end

    # Check if stdout is a TTY
    # @param output [IO] Output stream to check
    # @return [Boolean]
    def tty?(output = $stdout)
      Environment.tty?(output)
    end

    # Get terminal columns (width)
    # @param output [IO] Output stream
    # @param default [Integer] Default if detection fails
    # @return [Integer]
    def columns(output = $stdout, default: 80)
      Environment.columns(output, default: default)
    end

    # Get terminal rows (height)
    # @param output [IO] Output stream
    # @param default [Integer] Default if detection fails
    # @return [Integer]
    def rows(output = $stdout, default: 24)
      Environment.rows(output, default: default)
    end

    # Run the interactive demo showcasing all Clack features.
    # The demo implementation is in examples/demo.rb.
    #
    # @return [void]
    def demo
      demo_path = File.expand_path("../examples/demo.rb", __dir__)
      load demo_path
      run_demo
    end
  end
end

# Terminal cleanup on exit - show cursor if it was hidden
at_exit do
  print "\e[?25h"
end

# Chain INT handler to restore cursor before passing to previous handler
previous_int_handler = trap("INT") do
  print "\e[?25h"
  case previous_int_handler
  when Proc then previous_int_handler.call
  when "DEFAULT", "SYSTEM_DEFAULT" then exit(130)
  else exit(130)
  end
end

# Set up SIGWINCH handler for terminal resize
Clack::Core::Prompt.setup_signal_handler
