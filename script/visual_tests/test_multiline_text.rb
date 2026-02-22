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

Clack.intro "Multiline Text Edge Cases"

test("Basic multiline (Enter = newline, Ctrl+D = submit)") do
  Clack.multiline_text(
    message: "Write a commit message:"
  )
end

test("Multiline with initial value") do
  Clack.multiline_text(
    message: "Edit this message:",
    initial_value: "Line one\nLine two\nLine three"
  )
end

test("Multiline with validation") do
  Clack.multiline_text(
    message: "Write notes (required):",
    validate: ->(v) { "Cannot be empty" if v.strip.empty? }
  )
end

test("Multiline empty submit (just Ctrl+D immediately)") do
  Clack.multiline_text(
    message: "Optional notes (Ctrl+D to skip):"
  )
end

Clack.outro "Multiline text tests complete!"
