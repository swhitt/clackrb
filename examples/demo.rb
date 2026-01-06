#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script showcasing Clack Ruby prompts
# Run with: ruby examples/demo.rb

require_relative "../lib/clack"

# Welcome message
Clack.intro("Welcome to Clack Ruby!")

# Text prompt
name = Clack.text(
  message: "What is your name?",
  placeholder: "Enter your name",
  validate: ->(value) { "Name is required" if value.empty? }
)

if Clack.cancel?(name)
  Clack.cancel("Operation cancelled")
  exit 1
end

# Password prompt
password = Clack.password(
  message: "Create a password:",
  validate: ->(value) { "Password must be at least 4 characters" if value.length < 4 }
)

if Clack.cancel?(password)
  Clack.cancel("Operation cancelled")
  exit 1
end

# Confirm prompt
continue = Clack.confirm(
  message: "Would you like to continue?",
  initial_value: true
)

if Clack.cancel?(continue) || !continue
  Clack.cancel("Setup cancelled")
  exit 1
end

# Select prompt
language = Clack.select(
  message: "What is your favorite language?",
  options: [
    {value: "ruby", label: "Ruby", hint: "recommended"},
    {value: "python", label: "Python"},
    {value: "javascript", label: "JavaScript"},
    {value: "go", label: "Go"}
  ]
)

if Clack.cancel?(language)
  Clack.cancel("Operation cancelled")
  exit 1
end

# Multiselect prompt
features = Clack.multiselect(
  message: "Select features to enable:",
  options: [
    {value: "auth", label: "Authentication"},
    {value: "api", label: "API endpoints"},
    {value: "db", label: "Database integration"},
    {value: "cache", label: "Caching"}
  ],
  initial_values: ["auth"]
)

if Clack.cancel?(features)
  Clack.cancel("Operation cancelled")
  exit 1
end

# Spinner for async work
spinner = Clack.spinner
spinner.start("Setting up your project...")
sleep 1.5
spinner.stop("Project created successfully!")

# Note with summary
Clack.note(<<~NOTE, title: "Summary")
  Name: #{name}
  Language: #{language}
  Features: #{features.join(", ")}
NOTE

# Outro
Clack.outro("Thanks for using Clack Ruby! Happy coding!")
