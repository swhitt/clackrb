#!/usr/bin/env ruby
# frozen_string_literal: true

# Run with: ruby examples/images/spinner_example.rb

require_relative "../../lib/clack" # Or: require "clack" if installed as a gem

spinner = Clack.spinner
spinner.start("Installing dependencies...")
sleep 1.5
spinner.stop("Dependencies installed!")
