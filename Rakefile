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
