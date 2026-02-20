#!/usr/bin/env ruby
# frozen_string_literal: true

# Run with: ruby examples/images/multiselect_example.rb

require_relative "../../lib/clack" # Or: require "clack" if installed as a gem

Clack.multiselect(
  message: "Select features to install",
  options: [
    {value: "api", label: "API Mode"},
    {value: "auth", label: "Authentication"},
    {value: "jobs", label: "Background Jobs"}
  ]
)
