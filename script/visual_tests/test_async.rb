#!/usr/bin/env ruby
# frozen_string_literal: true

require "clack"

def test(name)
  puts
  puts "\e[1;36m--- TEST: #{name} ---\e[0m"
  puts
  result = yield
  if Clack.cancel?(result)
    Clack.log.warning "Cancelled"
  else
    Clack.log.success "Result: #{result.inspect}"
  end
  sleep 0.3
end

Clack.intro "Async Widget Edge Cases (Spinner, Tasks, Progress)"

test("Spinner with message updates") do
  s = Clack.spinner
  s.start "Step 1: Installing..."
  sleep 1
  s.message "Step 2: Compiling..."
  sleep 1
  s.message "Step 3: Finishing..."
  sleep 1
  s.stop "All done!"
  :ok
end

test("Spinner with error") do
  s = Clack.spinner
  s.start "Attempting risky operation..."
  sleep 1.5
  s.error "Something went wrong!"
  :error
end

test("Spinner cancel") do
  s = Clack.spinner
  s.start "Long running task..."
  sleep 1
  s.cancel "Aborted"
  :cancelled
end

test("Spin helper (success)") do
  Clack.spin("Processing data...") do |s|
    sleep 0.5
    s.message "Halfway there..."
    sleep 0.5
    "done"
  end
end

test("Tasks with message callbacks") do
  Clack.tasks(tasks: [
    {
      title: "Checking dependencies",
      task: -> { sleep 0.5 }
    },
    {
      title: "Installing packages",
      task: ->(message) {
        sleep 0.3
        message.call("Installing (1/3)...")
        sleep 0.3
        message.call("Installing (2/3)...")
        sleep 0.3
        message.call("Installing (3/3)...")
        sleep 0.3
      }
    },
    {
      title: "Building",
      task: -> { sleep 0.5 }
    }
  ])
end

test("Tasks with disabled task") do
  Clack.tasks(tasks: [
    {
      title: "Always runs",
      task: -> { sleep 0.3 }
    },
    {
      title: "Skipped task",
      enabled: false,
      task: -> { sleep 0.3 }
    },
    {
      title: "Also runs",
      task: -> { sleep 0.3 }
    }
  ])
end

test("Progress bar") do
  prog = Clack.progress(total: 30, message: "Downloading files...")
  prog.start
  30.times do
    sleep 0.05
    prog.advance
  end
  prog.stop("Download complete!")
  :ok
end

test("Progress bar with error") do
  prog = Clack.progress(total: 30, message: "Uploading...")
  prog.start
  15.times do
    sleep 0.05
    prog.advance
  end
  prog.error("Upload failed!")
  :error
end

Clack.outro "Async widget tests complete!"
