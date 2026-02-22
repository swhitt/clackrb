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

Clack.intro "Password Prompt Edge Cases"

test("Basic password with * mask") do
  Clack.password(
    message: "Enter your password:",
    mask: "*"
  )
end

test("Password with default block mask") do
  Clack.password(
    message: "Enter your API key:"
  )
end

test("Password with validation (min length)") do
  Clack.password(
    message: "Create a password (min 8 chars):",
    mask: "*",
    validate: ->(v) { "Must be at least 8 characters" if v.length < 8 }
  )
end

test("Password with emoji input") do
  Clack.password(
    message: "Enter emoji password:",
    mask: "🔒"
  )
end

test("Empty password (just hit Enter)") do
  Clack.password(
    message: "Optional password (can be empty):",
    mask: "*"
  )
end

Clack.outro "Password tests complete!"
