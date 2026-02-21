#!/usr/bin/env ruby
# frozen_string_literal: true

# Visual integration test script for browser-based testing via ttyd + Chrome MCP.
#
# Usage:
#   ruby -Ilib script/visual_test.rb           # Run all prompts sequentially
#   ruby -Ilib script/visual_test.rb select    # Run a single prompt type
#   ruby -Ilib script/visual_test.rb list      # List available prompt types
#
# Designed to be served via ttyd for browser-based interaction:
#   ttyd --writable ruby -Ilib script/visual_test.rb

require "clack"

PROMPTS = {
  "text" => -> {
    Clack.text(
      message: "What is your project name?",
      placeholder: "my-awesome-project",
      initial_value: "hello",
      validate: ->(v) { "Name is required" if v.strip.empty? }
    )
  },

  "password" => -> {
    Clack.password(
      message: "Enter your API key:",
      mask: "*"
    )
  },

  "confirm" => -> {
    Clack.confirm(
      message: "Deploy to production?",
      active: "Yes, ship it!",
      inactive: "No, abort",
      initial_value: false
    )
  },

  "select" => -> {
    Clack.select(
      message: "Choose a framework:",
      options: [
        {value: "rails", label: "Ruby on Rails", hint: "full-stack"},
        {value: "sinatra", label: "Sinatra", hint: "micro"},
        {value: "hanami", label: "Hanami", hint: "clean architecture"},
        {value: "roda", label: "Roda", hint: "routing tree"}
      ],
      initial_value: "rails"
    )
  },

  "multiselect" => -> {
    Clack.multiselect(
      message: "Select integrations:",
      options: [
        {value: "postgres", label: "PostgreSQL", hint: "recommended"},
        {value: "redis", label: "Redis"},
        {value: "sidekiq", label: "Sidekiq"},
        {value: "elasticsearch", label: "Elasticsearch"}
      ],
      initial_values: ["postgres"],
      required: true
    )
  },

  "group_multiselect" => -> {
    Clack.group_multiselect(
      message: "Select stack components:",
      selectable_groups: true,
      group_spacing: 1,
      required: true,
      options: [
        {
          label: "Frontend",
          options: [
            {value: "hotwire", label: "Hotwire"},
            {value: "stimulus", label: "Stimulus"},
            {value: "tailwind", label: "Tailwind CSS"}
          ]
        },
        {
          label: "Backend",
          options: [
            {value: "sidekiq", label: "Sidekiq"},
            {value: "solid_queue", label: "Solid Queue"},
            {value: "graphql", label: "GraphQL"}
          ]
        },
        {
          label: "Infrastructure",
          options: [
            {value: "docker", label: "Docker"},
            {value: "k8s", label: "Kubernetes"},
            {value: "terraform", label: "Terraform"}
          ]
        }
      ]
    )
  },

  "autocomplete" => -> {
    Clack.autocomplete(
      message: "Pick a license:",
      placeholder: "Type to search...",
      options: [
        {value: "mit", label: "MIT", hint: "permissive"},
        {value: "apache2", label: "Apache 2.0", hint: "permissive"},
        {value: "gpl3", label: "GPL 3.0", hint: "copyleft"},
        {value: "agpl3", label: "AGPL 3.0", hint: "copyleft"},
        {value: "bsd2", label: "BSD 2-Clause", hint: "permissive"},
        {value: "bsd3", label: "BSD 3-Clause", hint: "permissive"},
        {value: "mpl2", label: "MPL 2.0", hint: "weak copyleft"},
        {value: "unlicense", label: "Unlicense", hint: "public domain"}
      ]
    )
  },

  "autocomplete_multiselect" => -> {
    Clack.autocomplete_multiselect(
      message: "Select tags:",
      placeholder: "Type to filter...",
      options: %w[bug feature enhancement docs tests refactor performance security ci deploy],
      required: true
    )
  },

  "range" => -> {
    Clack.range(
      message: "Concurrency level:",
      min: 1,
      max: 16,
      step: 1,
      initial_value: 4
    )
  },

  "path" => -> {
    Clack.path(
      message: "Choose a file:",
      only_directories: false
    )
  },

  "date" => -> {
    Clack.date(
      message: "Schedule deployment:",
      format: :iso,
      initial_value: Date.today
    )
  },

  "spinner" => -> {
    s = Clack.spinner
    s.start "Installing dependencies..."
    sleep 1
    s.message "Compiling assets..."
    sleep 1
    s.message "Running migrations..."
    sleep 1
    s.stop "Ready!"
    :ok
  },

  "tasks" => -> {
    Clack.tasks(tasks: [
      {
        title: "Checking dependencies",
        task: -> { sleep 0.8 }
      },
      {
        title: "Installing packages",
        task: ->(message) {
          sleep 0.5
          message.call("Installing packages... (1/3) core")
          sleep 0.5
          message.call("Installing packages... (2/3) dev tools")
          sleep 0.5
          message.call("Installing packages... (3/3) plugins")
          sleep 0.5
        }
      },
      {
        title: "Compiling assets",
        task: -> { sleep 1 }
      }
    ])
  },

  "progress" => -> {
    prog = Clack.progress(total: 50, message: "Downloading...")
    prog.start
    50.times do
      sleep 0.06
      prog.advance
    end
    prog.stop("Download complete!")
    :ok
  },

  "select_key" => -> {
    Clack.select_key(
      message: "What next?",
      options: [
        {value: "init", label: "Initialize repo", key: "i", hint: "git init"},
        {value: "clone", label: "Clone existing", key: "c", hint: "git clone"},
        {value: "open", label: "Open in editor", key: "o"},
        {value: "skip", label: "Skip", key: "s"}
      ]
    )
  }
}

def run_prompt(name)
  puts
  puts "=== #{name.upcase} PROMPT ==="
  puts

  result = PROMPTS[name].call

  if Clack.cancel?(result)
    Clack.log.warning "Cancelled"
  else
    display = case result
    when Array then result.join(", ")
    else result.to_s
    end
    Clack.log.success "Result: #{display}"
  end

  sleep 0.5
end

def list_prompts
  puts "Available prompt types:"
  PROMPTS.each_key { |name| puts "  #{name}" }
end

# Main
filter = ARGV.first

if filter == "list"
  list_prompts
  exit 0
end

if filter
  unless PROMPTS.key?(filter)
    warn "Unknown prompt type: #{filter}"
    warn "Run with 'list' to see available types"
    exit 1
  end

  Clack.intro "visual-test (#{filter})"
  run_prompt(filter)
  Clack.outro "Done"
  exit 0
end

Clack.intro "visual-test"

PROMPTS.each_key do |name|
  run_prompt(name)
end

Clack.outro "All prompts complete!"
