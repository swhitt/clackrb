#!/usr/bin/env ruby
# frozen_string_literal: true

# Migration Guide: tty-prompt -> Clack
#
# This file shows common tty-prompt patterns and their Clack equivalents.
# Each section shows the tty-prompt code (commented out) followed by
# runnable Clack code that does the same thing.
#
# Run with: ruby examples/migration_from_tty_prompt.rb

require_relative "../lib/clack" # Or: require "clack" if installed as a gem

Clack.intro "Migrating from tty-prompt to Clack"

# ─────────────────────────────────────────────
# 1. Basic text input
# ─────────────────────────────────────────────
#
# tty-prompt:
#   prompt = TTY::Prompt.new
#   name = prompt.ask("What is your name?", default: "World")
#
# Clack equivalent:

name = Clack.text(
  message: "What is your name?",
  placeholder: "World",
  default_value: "World"
)
exit 0 if Clack.cancel?(name)

Clack.log.info "Name: #{name}"

# ─────────────────────────────────────────────
# 2. Password input
# ─────────────────────────────────────────────
#
# tty-prompt:
#   secret = prompt.mask("Enter your API key:")
#
# Clack equivalent:

secret = Clack.password(message: "Enter your API key:")
exit 0 if Clack.cancel?(secret)

Clack.log.info "Key entered (#{secret.length} chars)"

# ─────────────────────────────────────────────
# 3. Yes/No confirmation
# ─────────────────────────────────────────────
#
# tty-prompt:
#   prompt.yes?("Continue setup?")            # => true/false
#   prompt.no?("Skip optional steps?")        # => true/false (inverted default)
#
# Clack equivalent:
#   Use initial_value: false to mimic prompt.no? (default to "No")

continue = Clack.confirm(message: "Continue setup?")
exit 0 if Clack.cancel?(continue)

Clack.log.info "Continue: #{continue}"

# ─────────────────────────────────────────────
# 4. Single select
# ─────────────────────────────────────────────
#
# tty-prompt:
#   color = prompt.select("Pick a color", %w[Red Green Blue])
#
#   # or with values:
#   color = prompt.select("Pick a color") do |menu|
#     menu.choice "Red",   :red
#     menu.choice "Green", :green
#     menu.choice "Blue",  :blue
#   end
#
# Clack equivalent:

color = Clack.select(
  message: "Pick a color",
  options: [
    {value: :red, label: "Red"},
    {value: :green, label: "Green"},
    {value: :blue, label: "Blue"}
  ]
)
exit 0 if Clack.cancel?(color)

Clack.log.info "Color: #{color}"

# ─────────────────────────────────────────────
# 5. Multi-select
# ─────────────────────────────────────────────
#
# tty-prompt:
#   toppings = prompt.multi_select("Choose toppings") do |menu|
#     menu.choice "Cheese",     :cheese
#     menu.choice "Pepperoni",  :pepperoni
#     menu.choice "Mushrooms",  :mushrooms
#     menu.choice "Olives",     :olives
#   end
#
# Clack equivalent:

toppings = Clack.multiselect(
  message: "Choose toppings",
  options: [
    {value: :cheese, label: "Cheese"},
    {value: :pepperoni, label: "Pepperoni"},
    {value: :mushrooms, label: "Mushrooms"},
    {value: :olives, label: "Olives"}
  ],
  required: false
)
exit 0 if Clack.cancel?(toppings)

Clack.log.info "Toppings: #{toppings.join(", ")}"

# ─────────────────────────────────────────────
# 6. Autocomplete / filtering
# ─────────────────────────────────────────────
#
# tty-prompt:
#   lang = prompt.select("Pick a language", %w[Ruby Python JavaScript Go Rust], filter: true)
#
# Clack has a dedicated autocomplete prompt with built-in fuzzy matching:

lang = Clack.autocomplete(
  message: "Pick a language (type to filter)",
  options: [
    {value: "ruby", label: "Ruby"},
    {value: "python", label: "Python"},
    {value: "javascript", label: "JavaScript"},
    {value: "go", label: "Go"},
    {value: "rust", label: "Rust"}
  ]
)
exit 0 if Clack.cancel?(lang)

Clack.log.info "Language: #{lang}"

# ─────────────────────────────────────────────
# 7. Validation
# ─────────────────────────────────────────────
#
# tty-prompt:
#   email = prompt.ask("Email?", validate: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\z/i)
#   age   = prompt.ask("Age?") { |q| q.validate(->(v) { v.to_i > 0 }, "Must be positive") }
#
# Clack uses a validate lambda that returns nil (pass) or an error string:

email = Clack.text(
  message: "Email?",
  validate: ->(v) {
    "Invalid email" unless v.match?(/\A[\w+\-.]+@[a-z\d-]+(\.[a-z]+)*\z/i)
  }
)
exit 0 if Clack.cancel?(email)

Clack.log.info "Email: #{email}"

# ─────────────────────────────────────────────
# 8. Collecting multiple prompts (group)
# ─────────────────────────────────────────────
#
# tty-prompt:
#   result = prompt.collect do
#     key(:name).ask("Name?")
#     key(:role).select("Role?", %w[Admin User Guest])
#     key(:notify).yes?("Send welcome email?")
#   end
#   # => { name: "Alice", role: "User", notify: true }
#
# Clack.group collects answers into a hash and handles cancellation:

result = Clack.group(
  on_cancel: ->(_partial) {
    Clack.cancel "Setup cancelled"
    exit 0
  }
) do |g|
  g.prompt(:name) { Clack.text(message: "Name?", placeholder: "Alice") }

  g.prompt(:role) do
    Clack.select(
      message: "Role?",
      options: %w[Admin User Guest].map { |r| {value: r.downcase, label: r} }
    )
  end

  g.prompt(:notify) { Clack.confirm(message: "Send welcome email?") }
end

Clack.log.info "Name: #{result[:name]}"
Clack.log.info "Role: #{result[:role]}"
Clack.log.info "Notify: #{result[:notify]}"

# ─────────────────────────────────────────────
# Quick reference
# ─────────────────────────────────────────────

Clack.note <<~TABLE, title: "Quick Reference"
  tty-prompt              Clack
  ─────────────────────   ──────────────────────────────
  prompt.ask              Clack.text
  prompt.mask             Clack.password
  prompt.yes? / prompt.no?  Clack.confirm
  prompt.select           Clack.select
  prompt.multi_select     Clack.multiselect
  prompt.select(filter:)  Clack.autocomplete
  prompt.collect          Clack.group
  prompt.say / prompt.warn  Clack.log.info / .warning
  TTY::Spinner            Clack.spinner / Clack.spin
TABLE

Clack.outro "Migration complete! See the README for the full API."
