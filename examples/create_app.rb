#!/usr/bin/env ruby
# frozen_string_literal: true

# Run with: ruby examples/create_app.rb

require_relative "../lib/clack" # Or: require "clack" if installed as a gem

Clack.intro "create-my-app"

# Project name
name = Clack.text(
  message: "Project name?",
  placeholder: "my-app",
  validate: ->(v) { "Project name is required" if v.to_s.strip.empty? }
)
exit 0 if Clack.cancel?(name)

# Framework selection
framework = Clack.select(
  message: "Pick a framework",
  options: [
    {value: "rails", label: "Ruby on Rails", hint: "full-stack"},
    {value: "sinatra", label: "Sinatra", hint: "micro"},
    {value: "hanami", label: "Hanami"},
    {value: "roda", label: "Roda"}
  ]
)
exit 0 if Clack.cancel?(framework)

# Feature selection
features = Clack.multiselect(
  message: "Select features",
  options: [
    {value: "api", label: "API Mode"},
    {value: "auth", label: "Authentication"},
    {value: "admin", label: "Admin Panel"},
    {value: "docker", label: "Docker Setup"},
    {value: "ci", label: "GitHub Actions CI"}
  ],
  required: false
)
exit 0 if Clack.cancel?(features)

# Database
database = Clack.select(
  message: "Select database",
  options: [
    {value: "postgresql", label: "PostgreSQL", hint: "recommended"},
    {value: "mysql", label: "MySQL"},
    {value: "sqlite", label: "SQLite"}
  ]
)
exit 0 if Clack.cancel?(database)

# Confirm
proceed = Clack.confirm(message: "Create project?")
exit 0 if Clack.cancel?(proceed)

unless proceed
  Clack.outro "Project creation cancelled."
  exit 0
end

# Simulate installation
s = Clack.spinner
s.start "Creating project..."
sleep 1
s.message "Installing dependencies..."
sleep 1
s.message "Configuring #{framework}..."
sleep 0.5
s.stop "Project created!"

# Summary
Clack.log.info "Project: #{name}"
Clack.log.success "Framework: #{framework}"
Clack.log.step "Database: #{database}"
Clack.log.step "Features: #{features.join(", ")}" unless features.empty?

Clack.note <<~NOTE, title: "Next Steps"
  cd #{name}
  bundle install
  bin/rails server
NOTE

Clack.outro "Happy coding!"
