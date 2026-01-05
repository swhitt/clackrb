require_relative "clack/version"
require_relative "clack/symbols"
require_relative "clack/colors"
require_relative "clack/core/cursor"
require_relative "clack/core/settings"
require_relative "clack/core/key_reader"
require_relative "clack/core/prompt"
require_relative "clack/prompts/text"
require_relative "clack/prompts/password"
require_relative "clack/prompts/confirm"
require_relative "clack/prompts/select"
require_relative "clack/prompts/multiselect"
require_relative "clack/prompts/spinner"
require_relative "clack/log"
require_relative "clack/note"

module Clack
  CANCEL = Object.new.tap { |o| o.define_singleton_method(:inspect) { "Clack::CANCEL" } }.freeze

  class << self
    def cancel?(value)
      value.equal?(CANCEL)
    end

    # Session markers
    def intro(title = nil, output: $stdout)
      output.puts "#{Colors.gray(Symbols::S_BAR_START)}  #{title}"
      output.puts Colors.gray(Symbols::S_BAR)
    end

    def outro(message = nil, output: $stdout)
      output.puts Colors.gray(Symbols::S_BAR)
      output.puts "#{Colors.gray(Symbols::S_BAR_END)}  #{message}"
      output.puts
    end

    def cancel(message = nil, output: $stdout)
      output.puts Colors.gray(Symbols::S_BAR)
      output.puts "#{Colors.gray(Symbols::S_BAR_END)}  #{Colors.red(message)}"
      output.puts
    end

    # Prompts
    def text(message:, **opts)
      Prompts::Text.new(message:, **opts).run
    end

    def password(message:, **opts)
      Prompts::Password.new(message:, **opts).run
    end

    def confirm(message:, **opts)
      Prompts::Confirm.new(message:, **opts).run
    end

    def select(message:, options:, **opts)
      Prompts::Select.new(message:, options:, **opts).run
    end

    def multiselect(message:, options:, **opts)
      Prompts::Multiselect.new(message:, options:, **opts).run
    end

    def spinner(**opts)
      Prompts::Spinner.new(**opts)
    end

    # Logging
    def log
      Log
    end

    # Note box
    def note(message = "", title: nil, **opts)
      Note.render(message, title:, **opts)
    end

    # Demo - showcases all Clack features
    def demo
      intro "clack-demo"
      run_demo_prompts
    end

    private

    def run_demo_prompts
      name = demo_get_name or return
      demo_get_secret or return
      demo_confirm_continue or return
      framework = demo_select_framework or return
      features = demo_select_features or return
      demo_run_spinner
      demo_show_summary(name, framework, features)
    end

    def demo_get_name
      result = text(
        message: "What is your name?",
        placeholder: "Anonymous",
        validate: ->(val) { "Name is required" if val.to_s.strip.empty? }
      )
      cancelled?(result) ? nil : result
    end

    def demo_get_secret
      result = password(message: "Enter a secret")
      cancelled?(result) ? nil : result
    end

    def demo_confirm_continue
      result = confirm(message: "Continue with the demo?")
      return nil if cancelled?(result)
      return outro("Demo ended early") unless result
      result
    end

    def demo_select_framework
      result = select(
        message: "Pick a framework",
        options: [
          {value: "rails", label: "Ruby on Rails", hint: "recommended"},
          {value: "sinatra", label: "Sinatra"},
          {value: "hanami", label: "Hanami"},
          {value: "roda", label: "Roda"}
        ]
      )
      cancelled?(result) ? nil : result
    end

    def demo_select_features
      result = multiselect(
        message: "Select features",
        options: [
          {value: "api", label: "API Mode"},
          {value: "auth", label: "Authentication"},
          {value: "admin", label: "Admin Panel"},
          {value: "docker", label: "Docker Setup"}
        ],
        required: false
      )
      cancelled?(result) ? nil : result
    end

    def demo_run_spinner
      loading = spinner
      loading.start "Installing dependencies..."
      sleep 1.5
      loading.message "Configuring project..."
      sleep 1
      loading.stop "Setup complete!"
    end

    def demo_show_summary(name, framework, features)
      log.info "Project: #{name}"
      log.success "Framework: #{framework}"
      log.step "Features: #{features.join(", ")}" unless features.empty?
      note "Welcome to your new #{framework} project!", title: "Next Steps"
      outro "You're all set! Happy coding, #{name}!"
    end

    def cancelled?(value)
      return false unless cancel?(value)
      cancel("Cancelled")
      true
    end
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
