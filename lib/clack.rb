require_relative "clack/version"
require_relative "clack/symbols"
require_relative "clack/colors"
require_relative "clack/core/cursor"
require_relative "clack/core/settings"
require_relative "clack/core/key_reader"
require_relative "clack/core/prompt"
require_relative "clack/core/options_helper"
require_relative "clack/prompts/text"
require_relative "clack/prompts/password"
require_relative "clack/prompts/confirm"
require_relative "clack/prompts/select"
require_relative "clack/prompts/multiselect"
require_relative "clack/prompts/spinner"
require_relative "clack/prompts/autocomplete"
require_relative "clack/prompts/path"
require_relative "clack/prompts/progress"
require_relative "clack/prompts/select_key"
require_relative "clack/prompts/tasks"
require_relative "clack/prompts/group_multiselect"
require_relative "clack/log"
require_relative "clack/note"
require_relative "clack/group"
require_relative "clack/stream"

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

  class << self
    # Check if a prompt result was cancelled by the user.
    #
    # @param value [Object] the result from a prompt
    # @return [Boolean] true if the user cancelled
    def cancel?(value)
      value.equal?(CANCEL)
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
    # @param placeholder [String, nil] dim text shown when input is empty
    # @param default_value [String, nil] value used if submitted empty
    # @param initial_value [String, nil] pre-filled editable text
    # @param validate [Proc, nil] validation function returning error message or nil
    # @return [String, CANCEL] user input or CANCEL if cancelled
    def text(message:, **opts)
      Prompts::Text.new(message:, **opts).run
    end

    # Prompt for password input (masked display).
    #
    # @param message [String] the prompt message
    # @param mask [String] character to display for each input character (default: ▪)
    # @param validate [Proc, nil] validation function
    # @return [String, CANCEL] password or CANCEL if cancelled
    def password(message:, **opts)
      Prompts::Password.new(message:, **opts).run
    end

    # Prompt for yes/no confirmation.
    #
    # @param message [String] the prompt message
    # @param active [String] label for "yes" option (default: "Yes")
    # @param inactive [String] label for "no" option (default: "No")
    # @param initial_value [Boolean] default selection (default: true)
    # @return [Boolean, CANCEL] true/false or CANCEL if cancelled
    def confirm(message:, **opts)
      Prompts::Confirm.new(message:, **opts).run
    end

    # Prompt to select one option from a list.
    #
    # @param message [String] the prompt message
    # @param options [Array<Hash, String>] list of options
    # @param initial_value [Object, nil] value of initially selected option
    # @param max_items [Integer, nil] max visible items (enables scrolling)
    # @return [Object, CANCEL] selected value or CANCEL if cancelled
    def select(message:, options:, **opts)
      Prompts::Select.new(message:, options: options, **opts).run
    end

    # Prompt to select multiple options from a list.
    #
    # @param message [String] the prompt message
    # @param options [Array<Hash, String>] list of options
    # @param initial_values [Array, nil] initially selected values
    # @param required [Boolean] require at least one selection (default: true)
    # @param max_items [Integer, nil] max visible items (enables scrolling)
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

    # Prompt with type-to-filter autocomplete.
    #
    # @param message [String] the prompt message
    # @param options [Array<Hash, String>] list of options to filter
    # @param placeholder [String, nil] placeholder text
    # @return [Object, CANCEL] selected value or CANCEL if cancelled
    def autocomplete(message:, options:, **opts)
      Prompts::Autocomplete.new(message:, options: options, **opts).run
    end

    # Prompt for file/directory path with filesystem navigation.
    #
    # @param message [String] the prompt message
    # @param root [String] starting directory (default: ".")
    # @param only_directories [Boolean] only show directories (default: false)
    # @return [String, CANCEL] selected path or CANCEL if cancelled
    def path(message:, **opts)
      Prompts::Path.new(message:, **opts).run
    end

    # Create a progress bar for measurable operations.
    #
    # @param total [Integer] total number of steps
    # @param message [String, nil] optional message
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
    # @param initial_values [Array, nil] initially selected values
    # @param required [Boolean] require at least one selection (default: true)
    # @return [Array, CANCEL] selected values or CANCEL if cancelled
    def group_multiselect(message:, options:, **opts)
      Prompts::GroupMultiselect.new(message:, options: options, **opts).run
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

    # :nocov:
    # Demo - showcases all Clack features (interactive, tested manually)
    def demo
      intro "create-app"

      result = group(on_cancel: ->(_) { cancel("Operation cancelled.") }) do |g|
        g.prompt(:name) do
          text(
            message: "What is your project named?",
            placeholder: "my-app",
            validate: ->(v) { "Project name is required" if v.to_s.strip.empty? }
          )
        end

        g.prompt(:directory) do |r|
          text(
            message: "Where should we create your project?",
            initial_value: "./#{r[:name]}"
          )
        end

        g.prompt(:template) do
          select(
            message: "Which template would you like to use?",
            options: [
              {value: "default", label: "Default", hint: "recommended"},
              {value: "minimal", label: "Minimal", hint: "bare bones"},
              {value: "api", label: "API Only", hint: "no frontend"},
              {value: "full", label: "Full Stack", hint: "everything included"}
            ]
          )
        end

        g.prompt(:typescript) do
          confirm(
            message: "Would you like to use TypeScript?",
            initial_value: true
          )
        end

        g.prompt(:features) do
          multiselect(
            message: "Which features would you like to include?",
            options: [
              {value: "eslint", label: "ESLint", hint: "code linting"},
              {value: "prettier", label: "Prettier", hint: "code formatting"},
              {value: "tailwind", label: "Tailwind CSS", hint: "utility-first CSS"},
              {value: "docker", label: "Docker", hint: "containerization"},
              {value: "ci", label: "GitHub Actions", hint: "CI/CD pipeline"}
            ],
            initial_values: ["eslint", "prettier"],
            required: false
          )
        end

        g.prompt(:package_manager) do
          select(
            message: "Which package manager do you prefer?",
            options: [
              {value: "npm", label: "npm"},
              {value: "yarn", label: "yarn"},
              {value: "pnpm", label: "pnpm", hint: "recommended"},
              {value: "bun", label: "bun", hint: "fast"}
            ],
            initial_value: "pnpm"
          )
        end

        g.prompt(:git) do
          confirm(
            message: "Initialize a new git repository?",
            initial_value: true
          )
        end

        g.prompt(:install) do
          confirm(
            message: "Install dependencies?",
            initial_value: true
          )
        end
      end

      return if cancel?(result)

      # Run installation
      if result[:install]
        s = spinner
        s.start "Creating project structure..."
        sleep 0.8
        s.message "Installing dependencies via #{result[:package_manager]}..."
        sleep 1.2
        s.message "Configuring #{result[:template]} template..."
        sleep 0.6
        if result[:git]
          s.message "Initializing git repository..."
          sleep 0.4
        end
        s.stop "Project created successfully!"
      end

      # Summary
      log.step "Project: #{result[:name]}"
      log.step "Directory: #{result[:directory]}"
      log.step "Template: #{result[:template]}"
      log.step "TypeScript: #{result[:typescript] ? "Yes" : "No"}"
      log.step "Features: #{result[:features].join(", ")}" unless result[:features].empty?

      note <<~MSG, title: "Next steps"
        cd #{result[:directory]}
        #{result[:package_manager]} run dev
      MSG

      outro "Happy coding!"
    end
    # :nocov:

    private

    # :nocov:
    def cancelled?(value)
      return false unless cancel?(value)
      cancel("Cancelled")
      true
    end
    # :nocov:
  end
end

# Terminal cleanup on exit
at_exit do
  print "\e[?25h" # Show cursor
end

trap("INT") do
  print "\e[?25h"
  exit 130
end
