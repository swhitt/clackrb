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
    display = result.is_a?(Array) ? result.join(", ") : result.inspect
    Clack.log.success "Result: #{display}"
  end
  sleep 0.3
end

Clack.intro "Autocomplete Multiselect Edge Cases"

test("Basic autocomplete multiselect (required)") do
  Clack.autocomplete_multiselect(
    message: "Select tags:",
    placeholder: "Type to filter...",
    options: %w[bug feature enhancement docs tests refactor performance security ci deploy],
    required: true
  )
end

test("Autocomplete multiselect with initial values") do
  Clack.autocomplete_multiselect(
    message: "Select packages (some pre-selected):",
    placeholder: "Type to filter...",
    initial_values: ["rspec", "rubocop"],
    options: [
      {value: "rspec", label: "RSpec", hint: "testing"},
      {value: "rubocop", label: "RuboCop", hint: "linting"},
      {value: "reek", label: "Reek", hint: "smells"},
      {value: "simplecov", label: "SimpleCov", hint: "coverage"},
      {value: "brakeman", label: "Brakeman", hint: "security"},
      {value: "bundler-audit", label: "Bundler Audit", hint: "deps"},
      {value: "steep", label: "Steep", hint: "types"},
      {value: "yard", label: "YARD", hint: "docs"}
    ]
  )
end

test("Autocomplete multiselect NOT required") do
  Clack.autocomplete_multiselect(
    message: "Optional features:",
    placeholder: "Type to filter...",
    required: false,
    options: %w[Authentication Authorization Logging Monitoring Caching]
  )
end

test("Autocomplete multiselect - filter + toggle persistence") do
  Clack.autocomplete_multiselect(
    message: "Test: filter, toggle, clear filter, check selections persist:",
    placeholder: "Type 'a', toggle, then backspace to clear...",
    required: false,
    options: %w[alpha beta gamma delta epsilon zeta eta theta iota kappa]
  )
end

Clack.outro "Autocomplete multiselect tests complete!"
