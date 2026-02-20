#!/usr/bin/env ruby
# frozen_string_literal: true

# Run with: ruby examples/images/password_example.rb

require_relative "../../lib/clack" # Or: require "clack" if installed as a gem

Clack.password(
  message: "Enter your API key"
)
