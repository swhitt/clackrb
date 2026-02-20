#!/usr/bin/env ruby
# frozen_string_literal: true

# Run with: ruby examples/images/text_example.rb

require_relative "../../lib/clack" # Or: require "clack" if installed as a gem

Clack.text(
  message: "What is your project named?",
  placeholder: "my-project"
)
