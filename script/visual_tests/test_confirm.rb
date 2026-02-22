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

Clack.intro "Confirm Prompt Edge Cases"

test("Basic confirm (default true)") do
  Clack.confirm(message: "Continue?")
end

test("Confirm with default false") do
  Clack.confirm(
    message: "Deploy to production?",
    initial_value: false
  )
end

test("Confirm with custom labels") do
  Clack.confirm(
    message: "Overwrite existing file?",
    active: "Overwrite",
    inactive: "Keep existing"
  )
end

test("Confirm with long labels") do
  Clack.confirm(
    message: "Accept terms and conditions?",
    active: "I accept the terms and conditions",
    inactive: "I do not accept"
  )
end

Clack.outro "Confirm tests complete!"
