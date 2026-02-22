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

Clack.intro "Multiselect Prompt Edge Cases"

test("Basic multiselect (required)") do
  Clack.multiselect(
    message: "Select features:",
    options: %w[Auth Database Cache Queue Search],
    required: true
  )
end

test("Multiselect with initial values") do
  Clack.multiselect(
    message: "Select tools (some pre-selected):",
    options: [
      {value: "rspec", label: "RSpec"},
      {value: "rubocop", label: "RuboCop"},
      {value: "reek", label: "Reek"},
      {value: "simplecov", label: "SimpleCov"},
      {value: "brakeman", label: "Brakeman"}
    ],
    initial_values: ["rspec", "rubocop"]
  )
end

test("Multiselect NOT required (can submit empty)") do
  Clack.multiselect(
    message: "Optional extras:",
    options: %w[Docs Tests Linting CI],
    required: false
  )
end

test("Multiselect with disabled options") do
  Clack.multiselect(
    message: "Select integrations:",
    options: [
      {value: "slack", label: "Slack"},
      {value: "teams", label: "Teams", hint: "enterprise only", disabled: true},
      {value: "discord", label: "Discord"},
      {value: "webhook", label: "Webhook"}
    ],
    required: false
  )
end

test("Multiselect with scrolling (max_items: 4)") do
  Clack.multiselect(
    message: "Pick toppings (scroll!):",
    max_items: 4,
    required: false,
    options: %w[Cheese Pepperoni Mushroom Onion Pepper Olive Bacon Ham Pineapple Jalapeño Anchovy Sausage]
  )
end

test("Multiselect - try 'a' for select-all, 'i' for invert") do
  Clack.multiselect(
    message: "Test toggle-all (a) and invert (i):",
    options: %w[Alpha Beta Gamma Delta Epsilon],
    required: false
  )
end

test("Multiselect with cursor_at") do
  Clack.multiselect(
    message: "Cursor starts at 'Gamma':",
    options: [
      {value: "alpha", label: "Alpha"},
      {value: "beta", label: "Beta"},
      {value: "gamma", label: "Gamma"},
      {value: "delta", label: "Delta"}
    ],
    cursor_at: "gamma",
    required: false
  )
end

Clack.outro "Multiselect tests complete!"
