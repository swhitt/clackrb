# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)

desc "Run all checks"
task default: %i[standard spec]

desc "Run with coverage"
task :coverage do
  ENV["COVERAGE"] = "true"
  Rake::Task[:spec].invoke
end

desc "Run the demo"
task :demo do
  require_relative "lib/clack"
  Clack.demo
end

desc "Start visual test server (ttyd) for browser-based integration testing"
task :visual_test do
  port = ENV.fetch("PORT", "7681")
  script = ENV.fetch("SCRIPT", "script/visual_test.rb")
  puts "Starting visual test at http://localhost:#{port}"
  puts "Press Ctrl+C to stop"
  exec "ttyd", "-p", port, "--writable", "ruby", "-Ilib", script
end
