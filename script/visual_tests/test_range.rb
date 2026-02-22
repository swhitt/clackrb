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

Clack.intro "Range Prompt Edge Cases"

test("Basic range (1-16, step 1)") do
  Clack.range(
    message: "Concurrency level:",
    min: 1,
    max: 16,
    step: 1,
    initial_value: 4
  )
end

test("Range with large step") do
  Clack.range(
    message: "Volume (step 10):",
    min: 0,
    max: 100,
    step: 10,
    initial_value: 50
  )
end

test("Range starting at min") do
  Clack.range(
    message: "Test clamping at min (try going left):",
    min: 0,
    max: 10,
    step: 1,
    initial_value: 0
  )
end

test("Range starting at max") do
  Clack.range(
    message: "Test clamping at max (try going right):",
    min: 0,
    max: 10,
    step: 1,
    initial_value: 10
  )
end

test("Range with validation") do
  Clack.range(
    message: "Pick even number only:",
    min: 1,
    max: 10,
    step: 1,
    initial_value: 2,
    validate: ->(v) { "Must be even" if v.odd? }
  )
end

test("Small range (0-1)") do
  Clack.range(
    message: "Binary choice as range:",
    min: 0,
    max: 1,
    step: 1
  )
end

Clack.outro "Range tests complete!"
