#!/usr/bin/env ruby
# frozen_string_literal: true

# Demonstrates advanced prompt types: multiline_text, path, select_key, autocomplete
# Run with: ruby examples/advanced_prompts.rb

require_relative "../lib/clack" # Or: require "clack" if installed as a gem

Clack.intro "advanced-prompts"

# Multi-line text with initial value (Ctrl+D to submit)
description = Clack.multiline_text(
  message: "Project description:",
  initial_value: "A Ruby CLI tool that "
)
exit 0 if Clack.cancel?(description)

Clack.log.info "Description:\n#{description}"

# Path selector (directories only, rooted at home)
project_dir = Clack.path(
  message: "Choose project directory:",
  root: Dir.home,
  only_directories: true
)
exit 0 if Clack.cancel?(project_dir)

Clack.log.info "Directory: #{project_dir}"

# Select by key press (instant selection)
action = Clack.select_key(
  message: "What next?",
  options: [
    {value: "init", label: "Initialize repo", key: "i", hint: "git init"},
    {value: "clone", label: "Clone existing", key: "c", hint: "git clone"},
    {value: "open", label: "Open in editor", key: "o"},
    {value: "skip", label: "Skip", key: "s"}
  ]
)
exit 0 if Clack.cancel?(action)

Clack.log.step "Action: #{action}"

# Autocomplete with placeholder
license = Clack.autocomplete(
  message: "Pick a license:",
  placeholder: "Type to search...",
  options: [
    {value: "mit", label: "MIT", hint: "permissive"},
    {value: "apache2", label: "Apache 2.0", hint: "permissive"},
    {value: "gpl3", label: "GPL 3.0", hint: "copyleft"},
    {value: "agpl3", label: "AGPL 3.0", hint: "copyleft"},
    {value: "bsd2", label: "BSD 2-Clause", hint: "permissive"},
    {value: "bsd3", label: "BSD 3-Clause", hint: "permissive"},
    {value: "mpl2", label: "MPL 2.0", hint: "weak copyleft"},
    {value: "unlicense", label: "Unlicense", hint: "public domain"}
  ]
)
exit 0 if Clack.cancel?(license)

Clack.log.success "License: #{license}"

Clack.outro "Done!"
