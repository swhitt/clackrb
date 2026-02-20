#!/usr/bin/env ruby
# frozen_string_literal: true

# Run with: ruby examples/date_demo.rb

require_relative "../lib/clack" # Or: require "clack" if installed as a gem

Clack.intro "date-picker-demo"

# Basic date selection
date = Clack.date(
  message: "When should this deploy?",
  help: "Use Tab/arrows to navigate, Up/Down to adjust, or type digits"
)
exit 0 if Clack.cancel?(date)

Clack.log.info "Selected: #{date}"

# Date with bounds
bounded_date = Clack.date(
  message: "Pick a date this year",
  format: :us,
  initial_value: Date.today,
  min: Date.new(Date.today.year, 1, 1),
  max: Date.new(Date.today.year, 12, 31)
)
exit 0 if Clack.cancel?(bounded_date)

Clack.log.info "Bounded date: #{bounded_date}"

# Date with custom validation
future_date = Clack.date(
  message: "Schedule for future date",
  validate: Clack::Validators.future_date
)
exit 0 if Clack.cancel?(future_date)

Clack.log.success "Scheduled for #{future_date}"

Clack.outro "Done!"
