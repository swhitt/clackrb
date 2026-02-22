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

Clack.intro "Select Key Edge Cases"

test("Basic select key") do
  Clack.select_key(
    message: "What next?",
    options: [
      {value: "init", label: "Initialize", key: "i"},
      {value: "clone", label: "Clone", key: "c"},
      {value: "open", label: "Open", key: "o"},
      {value: "skip", label: "Skip", key: "s"}
    ]
  )
end

test("Select key - try pressing wrong keys first") do
  Clack.select_key(
    message: "Press 'y' or 'n' (other keys should be ignored):",
    options: [
      {value: "yes", label: "Yes", key: "y"},
      {value: "no", label: "No", key: "n"}
    ]
  )
end

test("Select key with hints") do
  Clack.select_key(
    message: "Quick action:",
    options: [
      {value: "run", label: "Run tests", key: "r", hint: "bundle exec rspec"},
      {value: "lint", label: "Lint code", key: "l", hint: "standardrb"},
      {value: "build", label: "Build gem", key: "b", hint: "gem build"}
    ]
  )
end

Clack.outro "Select key tests complete!"
