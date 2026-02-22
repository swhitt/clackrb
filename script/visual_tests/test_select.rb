#!/usr/bin/env ruby
# frozen_string_literal: true

require "clack"

def test(name)
  puts
  puts "\e[1;36m--- TEST: #{name} ---\e[0m"
  puts
  result = yield
  if Clack.cancel?(result)
    Clack.log.warning "Cancelled"
  else
    Clack.log.success "Result: #{result.inspect}"
  end
  sleep 0.3
end

Clack.intro "Select Prompt Edge Cases"

test("Basic select (4 options)") do
  Clack.select(
    message: "Choose a framework:",
    options: [
      {value: "rails", label: "Ruby on Rails", hint: "full-stack"},
      {value: "sinatra", label: "Sinatra", hint: "micro"},
      {value: "hanami", label: "Hanami", hint: "clean"},
      {value: "roda", label: "Roda", hint: "routing"}
    ]
  )
end

test("Select with initial value (not first)") do
  Clack.select(
    message: "Default to Hanami:",
    options: [
      {value: "rails", label: "Ruby on Rails"},
      {value: "sinatra", label: "Sinatra"},
      {value: "hanami", label: "Hanami"},
      {value: "roda", label: "Roda"}
    ],
    initial_value: "hanami"
  )
end

test("Select with disabled options") do
  Clack.select(
    message: "Choose database (some unavailable):",
    options: [
      {value: "postgres", label: "PostgreSQL"},
      {value: "mysql", label: "MySQL", hint: "coming soon", disabled: true},
      {value: "sqlite", label: "SQLite"},
      {value: "mongodb", label: "MongoDB", hint: "deprecated", disabled: true},
      {value: "redis", label: "Redis"}
    ]
  )
end

test("Select with scrolling (max_items: 3)") do
  Clack.select(
    message: "Choose a language (scroll!):",
    max_items: 3,
    options: [
      {value: "ruby", label: "Ruby"},
      {value: "python", label: "Python"},
      {value: "javascript", label: "JavaScript"},
      {value: "typescript", label: "TypeScript"},
      {value: "go", label: "Go"},
      {value: "rust", label: "Rust"},
      {value: "elixir", label: "Elixir"},
      {value: "crystal", label: "Crystal"},
      {value: "zig", label: "Zig"},
      {value: "nim", label: "Nim"}
    ]
  )
end

test("Select with only 2 options") do
  Clack.select(
    message: "Binary choice:",
    options: %w[Yes No]
  )
end

test("Select with 1 option (degenerate)") do
  Clack.select(
    message: "Only one choice:",
    options: [{value: "only", label: "The Only Option"}]
  )
end

test("Select with string options (no hashes)") do
  Clack.select(
    message: "Pick a fruit:",
    options: %w[Apple Banana Cherry Date Elderberry]
  )
end

Clack.outro "Select tests complete!"
