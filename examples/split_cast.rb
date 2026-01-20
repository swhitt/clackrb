#!/usr/bin/env ruby
# frozen_string_literal: true

# Post-process asciinema cast to split batched terminal redraws into separate frames.
# This makes typing visible in the resulting GIF.
#
# Usage: ruby examples/split_cast.rb

require "json"

CAST_FILE = "examples/demo.cast"

lines = File.readlines(CAST_FILE)
header = lines.shift
output = [header.strip]

current_time = 0.0

lines.each do |line|
  next if line.strip.empty?

  event = JSON.parse(line)
  time, type, data = event

  current_time = time if time > 0

  # Look for multiple prompt redraws (cursor up 4 lines + clear)
  redraw_marker = "\e[4A\e[1G\e[J"

  if data.include?(redraw_marker)
    parts = data.split(redraw_marker)
    parts.each_with_index do |part, i|
      next if part.strip.empty?

      part_data = (i == 0) ? part : (redraw_marker + part)
      new_time = current_time + (i * 0.2)
      output << JSON.generate([new_time.round(3), type, part_data])
    end
    current_time += parts.length * 0.2
  else
    output << JSON.generate([current_time.round(3), type, data])
  end
end

File.write(CAST_FILE, output.join("\n") + "\n")
puts "Split into #{output.length} events"
