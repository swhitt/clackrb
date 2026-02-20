#!/usr/bin/env ruby
# frozen_string_literal: true

# Run with: ruby examples/images/select_example.rb

require_relative "../../lib/clack" # Or: require "clack" if installed as a gem

Clack.select(
  message: "Choose a database",
  options: [
    {value: "pg", label: "PostgreSQL", hint: "recommended"},
    {value: "mysql", label: "MySQL"},
    {value: "sqlite", label: "SQLite"}
  ]
)
