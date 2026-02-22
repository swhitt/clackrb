#!/usr/bin/env ruby
# frozen_string_literal: true

require "clack"
require "date"

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

Clack.intro "Date Prompt Edge Cases"

test("ISO format (YYYY-MM-DD)") do
  Clack.date(
    message: "Pick a date (ISO):",
    format: :iso,
    initial_value: Date.today
  )
end

test("US format (MM/DD/YYYY)") do
  Clack.date(
    message: "Pick a date (US):",
    format: :us,
    initial_value: Date.today
  )
end

test("EU format (DD.MM.YYYY)") do
  Clack.date(
    message: "Pick a date (EU):",
    format: :eu,
    initial_value: Date.today
  )
end

test("Date with min/max bounds") do
  Clack.date(
    message: "Pick a date this week:",
    format: :iso,
    initial_value: Date.today,
    min: Date.today - 3,
    max: Date.today + 3
  )
end

test("Date with validation") do
  Clack.date(
    message: "Pick a weekday:",
    format: :iso,
    initial_value: Date.today,
    validate: ->(d) { "Must be a weekday" if d.saturday? || d.sunday? }
  )
end

test("February edge case (try Feb 29/30/31)") do
  Clack.date(
    message: "Test Feb boundary (try changing month to 2):",
    format: :iso,
    initial_value: Date.new(2024, 1, 31)
  )
end

Clack.outro "Date tests complete!"
