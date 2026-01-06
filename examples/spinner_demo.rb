#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/clack"

Clack.intro "spinner-demo"

# Success state
s = Clack.spinner
s.start "Installing dependencies..."
sleep 2
s.stop "Dependencies installed!"

# Update message mid-spin
s = Clack.spinner
s.start "Building project..."
sleep 1
s.message "Compiling assets..."
sleep 1
s.message "Optimizing bundles..."
sleep 1
s.stop "Build complete!"

# Error state
s = Clack.spinner
s.start "Running tests..."
sleep 1.5
s.error "Tests failed!"

# Cancel state
s = Clack.spinner
s.start "Deploying to production..."
sleep 1
s.cancel "Deployment cancelled"

Clack.outro "Demo complete!"
