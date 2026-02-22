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

Clack.intro "Text Prompt Edge Cases"

test("Basic text with validation") do
  Clack.text(
    message: "Enter your name (required):",
    validate: ->(v) { "Name cannot be empty" if v.strip.empty? }
  )
end

test("Text with placeholder") do
  Clack.text(
    message: "Project name:",
    placeholder: "my-awesome-project"
  )
end

test("Text with initial value") do
  Clack.text(
    message: "Edit the greeting:",
    initial_value: "Hello, World!"
  )
end

test("Text with default value (submit empty)") do
  Clack.text(
    message: "Port number:",
    default_value: "3000",
    placeholder: "3000"
  )
end

test("Text with tab completions") do
  Clack.text(
    message: "Choose a color:",
    completions: %w[red green blue yellow purple orange],
    placeholder: "type and press Tab..."
  )
end

test("Text with transform (strip + downcase)") do
  Clack.text(
    message: "Username (will be lowercased):",
    transform: ->(v) { v.strip.downcase }
  )
end

test("Text with warning validation") do
  Clack.text(
    message: "Enter a filename:",
    validate: ->(v) {
      return "Filename required" if v.strip.empty?
      Clack.warning("File already exists. Press Enter to overwrite.") if v.include?("test")
    }
  )
end

test("Long text input stress test") do
  Clack.text(
    message: "Paste something long:",
    placeholder: "try typing a very long string..."
  )
end

test("Unicode / emoji input") do
  Clack.text(
    message: "Type some emoji or unicode:",
    placeholder: "e.g. Hello 🌍"
  )
end

Clack.outro "Text tests complete!"
