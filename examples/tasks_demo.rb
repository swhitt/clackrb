#!/usr/bin/env ruby
# frozen_string_literal: true

# Demonstrates Clack.tasks and Clack.task_log
# Run with: ruby examples/tasks_demo.rb

require_relative "../lib/clack" # Or: require "clack" if installed as a gem

Clack.intro "tasks-demo"

# Sequential tasks with spinner (message callback updates the spinner text)
Clack.tasks(tasks: [
  {
    title: "Checking dependencies",
    task: -> {
      sleep 1
    }
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
    task: -> {
      sleep 1.5
    }
  }
])

# Task log with streaming output
tl = Clack.task_log(title: "Running test suite", limit: 5)

test_files = %w[
  models/user_test.rb
  models/post_test.rb
  controllers/auth_test.rb
  controllers/api_test.rb
  helpers/format_test.rb
  integration/signup_test.rb
  integration/login_test.rb
]

test_files.each do |file|
  tl.message "Running #{file}..."
  sleep 0.3
end

tl.success "All #{test_files.length} test files passed!"

Clack.outro "Done!"
