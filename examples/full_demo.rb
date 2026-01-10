#!/usr/bin/env ruby
# frozen_string_literal: true

# Full Clack demo - showcases all features with realistic interactions
# Run with: ruby examples/full_demo.rb

require_relative "../lib/clack"

Clack.intro "create-app"

# Text input with placeholder
name = Clack.text(
  message: "Project name",
  placeholder: "my-project",
  validate: lambda { |v|
    return "Project name is required" if v.strip.empty?
    "Use lowercase letters, numbers, and dashes only" unless v.match?(/\A[a-z0-9-]+\z/)
  }
)
exit 1 if Clack.handle_cancel(name)

# Password with real validation rules + entropy warning
password = Clack.password(
  message: "Database password",
  validate: lambda { |v|
    return "Password must be at least 8 characters" if v.length < 8
    return "Password must include a number" unless v.match?(/\d/)
    return "Password must include a letter" unless v.match?(/[a-zA-Z]/)

    # Warn on predictable patterns like "password1" or "abcdef12"
    if v.match?(/^[a-z]+\d+$/i)
      Clack.warning("This password may be easy to guess")
    end
  }
)
exit 1 if Clack.handle_cancel(password)

# Simple confirm
use_typescript = Clack.confirm(
  message: "Use TypeScript?",
  initial_value: true
)
exit 1 if Clack.handle_cancel(use_typescript)

# Select with hints
framework = Clack.select(
  message: "Framework",
  options: [
    {value: "rails", label: "Rails", hint: "full-stack"},
    {value: "sinatra", label: "Sinatra", hint: "lightweight"},
    {value: "hanami", label: "Hanami", hint: "modular"},
    {value: "roda", label: "Roda", hint: "routing tree"}
  ]
)
exit 1 if Clack.handle_cancel(framework)

# Select key for quick selection
database = Clack.select_key(
  message: "Database",
  options: [
    {value: "postgres", label: "PostgreSQL", key: "p"},
    {value: "mysql", label: "MySQL", key: "m"},
    {value: "sqlite", label: "SQLite", key: "s"}
  ]
)
exit 1 if Clack.handle_cancel(database)

# Multiselect
gems = Clack.multiselect(
  message: "Dependencies",
  options: [
    {value: "rspec", label: "RSpec", hint: "testing"},
    {value: "sidekiq", label: "Sidekiq", hint: "background jobs"},
    {value: "redis", label: "Redis"},
    {value: "rubocop", label: "RuboCop", hint: "linting"}
  ],
  required: false
)
exit 1 if Clack.handle_cancel(gems)

# Autocomplete for filtering long lists
template = Clack.autocomplete(
  message: "Starter template",
  options: [
    "API only",
    "Full stack",
    "Admin panel",
    "GraphQL API",
    "Microservice",
    "Monolith",
    "Event-driven",
    "Serverless"
  ]
)
exit 1 if Clack.handle_cancel(template)

# Group multiselect for categorized options
extras = Clack.group_multiselect(
  message: "Additional setup",
  options: [
    {
      label: "CI/CD",
      options: [
        {value: "github_actions", label: "GitHub Actions"},
        {value: "gitlab_ci", label: "GitLab CI"},
        {value: "circleci", label: "CircleCI"}
      ]
    },
    {
      label: "Deployment",
      options: [
        {value: "docker", label: "Docker"},
        {value: "kamal", label: "Kamal"},
        {value: "heroku", label: "Heroku"}
      ]
    }
  ],
  required: false
)
exit 1 if Clack.handle_cancel(extras)

# Path with file exists warning
config_file = Clack.text(
  message: "Config file",
  default_value: "config.yml",
  validate: lambda { |v|
    return "Filename is required" if v.strip.empty?

    Clack::Validators.file_exists_warning("File exists. Overwrite?").call(v)
  }
)
exit 1 if Clack.handle_cancel(config_file)

# Progress bar
Clack.log.step "Scaffolding project..."
prog = Clack.progress(total: 100, message: "Creating files...")
prog.start
[20, 45, 70, 90, 100].each do |pct|
  sleep 0.12
  prog.advance(pct - prog.instance_variable_get(:@current))
end
prog.stop("Files created")

# Tasks
Clack.tasks(tasks: [
  {title: "Installing dependencies", task: -> { sleep 0.4 }},
  {title: "Configuring #{database}", task: -> { sleep 0.3 }},
  {title: "Running initial migration", task: -> { sleep 0.3 }}
])

# Spinner for final setup
s = Clack.spinner
s.start "Finalizing..."
sleep 0.5
s.message "Almost done..."
sleep 0.4
s.stop "Ready"

# Summary
Clack.log.success "Project created"
Clack.log.step "Name: #{name}"
Clack.log.step "Framework: #{framework}"
Clack.log.step "Database: #{database}"
Clack.log.step "Template: #{template}"
Clack.log.step "Gems: #{gems.join(", ")}" unless gems.empty?

Clack.note <<~MSG, title: "Next steps"
  cd #{name}
  bin/setup
  bin/dev
MSG

Clack.outro "Happy hacking!"
