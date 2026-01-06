#!/usr/bin/env ruby
# frozen_string_literal: true

# Full demo showcasing ALL Clack Ruby features
# Run with: ruby examples/full_demo.rb

require_relative "../lib/clack"

Clack.intro "create-app"

Clack.box "Welcome to the Ruby app generator", title: "create-app"

# Text input
name = Clack.text(
  message: "What is your project named?",
  placeholder: "my-app"
)
exit 1 if Clack.handle_cancel(name)

# Password input (masked)
api_key = Clack.password(
  message: "Enter your API key:",
  mask: "*"
)
exit 1 if Clack.handle_cancel(api_key)

# Confirm
use_rails = Clack.confirm(
  message: "Use Rails?",
  initial_value: true
)
exit 1 if Clack.handle_cancel(use_rails)

# Select (single choice)
ruby_version = Clack.select(
  message: "Select Ruby version:",
  options: [
    {value: "3.4", label: "Ruby 3.4", hint: "latest"},
    {value: "3.3", label: "Ruby 3.3", hint: "stable"},
    {value: "3.2", label: "Ruby 3.2"},
    {value: "jruby", label: "JRuby 9.4"}
  ]
)
exit 1 if Clack.handle_cancel(ruby_version)

# Multiselect
gems = Clack.multiselect(
  message: "Add dependencies:",
  options: [
    {value: "sidekiq", label: "Sidekiq", hint: "background jobs"},
    {value: "redis", label: "Redis"},
    {value: "rspec", label: "RSpec"},
    {value: "rubocop", label: "RuboCop"},
    {value: "puma", label: "Puma"}
  ],
  required: false
)
exit 1 if Clack.handle_cancel(gems)

# Select Key (quick keyboard shortcuts)
db = Clack.select_key(
  message: "Choose database:",
  options: [
    {value: "postgres", label: "PostgreSQL", key: "p"},
    {value: "mysql", label: "MySQL", key: "m"},
    {value: "sqlite", label: "SQLite", key: "s"}
  ]
)
exit 1 if Clack.handle_cancel(db)

# Autocomplete (type to filter)
template = Clack.autocomplete(
  message: "Choose starter template:",
  options: [
    "API only", "Full stack", "Hotwire", "GraphQL",
    "Minimal", "Monolith", "Microservice", "Admin panel",
    "E-commerce", "Blog", "SaaS starter"
  ]
)
exit 1 if Clack.handle_cancel(template)

# Autocomplete Multiselect (type to filter + select multiple)
services = Clack.autocomplete_multiselect(
  message: "Add third-party services:",
  options: [
    "Stripe", "AWS S3", "SendGrid", "Twilio", "Sentry",
    "New Relic", "Datadog", "Auth0", "Cloudflare", "Heroku",
    "Fly.io", "Redis Cloud", "Elasticsearch", "Algolia"
  ],
  required: false
)
exit 1 if Clack.handle_cancel(services)

# Path picker
directory = Clack.path(
  message: "Where should we create the project?",
  only_directories: true
)
exit 1 if Clack.handle_cancel(directory)

# Group Multiselect (categorized options)
extras = Clack.group_multiselect(
  message: "Additional configuration:",
  options: [
    {
      label: "Frontend",
      options: [
        {value: "importmaps", label: "Import Maps"},
        {value: "tailwind", label: "Tailwind CSS"},
        {value: "stimulus", label: "Stimulus"}
      ]
    },
    {
      label: "Testing",
      options: [
        {value: "factory_bot", label: "FactoryBot"},
        {value: "capybara", label: "Capybara"},
        {value: "vcr", label: "VCR"}
      ]
    },
    {
      label: "DevOps",
      options: [
        {value: "docker", label: "Docker"},
        {value: "github_actions", label: "GitHub Actions"},
        {value: "kamal", label: "Kamal", hint: "deployment"}
      ]
    }
  ],
  required: false
)
exit 1 if Clack.handle_cancel(extras)

# Progress bar
prog = Clack.progress(total: 100, message: "Downloading templates...")
prog.start
5.times do
  sleep 0.15
  prog.advance(20)
end
prog.stop("Templates ready")

# Tasks (multiple sequential operations)
Clack.tasks(tasks: [
  {title: "Creating directory structure", task: -> { sleep 0.3 }},
  {title: "Generating Gemfile", task: -> { sleep 0.3 }},
  {title: "Configuring database", task: -> { sleep 0.3 }},
  {title: "Setting up tests", task: -> { sleep 0.3 }}
])

# Spinner
s = Clack.spinner
s.start "Installing gems..."
sleep 0.8
s.message "Running bundle install..."
sleep 0.6
s.message "Finalizing setup..."
sleep 0.5
s.stop "Setup complete"

# Log output
Clack.log.step "Project: #{name}"
Clack.log.step "Ruby: #{ruby_version}"
Clack.log.step "Database: #{db}"
Clack.log.step "Template: #{template}"
Clack.log.step "Gems: #{gems.join(", ")}" unless gems.empty?
Clack.log.step "Services: #{services.join(", ")}" unless services.empty?

# Note (info box)
Clack.note <<~MSG, title: "Next steps"
  cd #{directory}/#{name}
  bin/setup
  bin/dev
MSG

Clack.outro "Happy hacking!"
