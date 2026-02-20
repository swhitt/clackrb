#!/usr/bin/env ruby
# frozen_string_literal: true

# Run with: ruby examples/images/confirm_example.rb

require_relative "../../lib/clack" # Or: require "clack" if installed as a gem

Clack.confirm(
  message: "Deploy to production?",
  active: "Yes, ship it!",
  inactive: "No, abort"
)
