# frozen_string_literal: true

# Shared examples for cancellable prompts
RSpec.shared_examples "a cancellable prompt" do
  it "can cancel with escape" do
    stub_keys(:escape)
    result = subject.run
    expect(Clack.cancel?(result)).to be true
  end

  it "can cancel with Ctrl+C" do
    stub_keys(:ctrl_c)
    result = subject.run
    expect(Clack.cancel?(result)).to be true
  end
end

# Test helpers for simulating user input
module TestHelpers
  # Key constants matching what KeyReader returns
  KEYS = {
    enter: "\r",
    escape: "\e",
    ctrl_c: "\u0003",
    ctrl_d: "\u0004",
    up: "\e[A",
    down: "\e[B",
    right: "\e[C",
    left: "\e[D",
    backspace: "\u007F",
    space: " ",
    tab: "\t"
  }.freeze

  # Helper to create a key sequence for stubbing KeyReader
  # Strings longer than 1 char are split into individual characters
  # Escape sequences (starting with \e) are kept as-is
  # nil values are converted to empty strings (ignored by prompts)
  def key_sequence(*keys)
    keys.flat_map do |key|
      case key
      when Symbol
        KEYS[key] || raise("Unknown key: #{key}")
      when String
        if key.start_with?("\e") || key.length <= 1
          key
        else
          key.chars # Split multi-char string into array of single chars
        end
      when NilClass
        "" # Convert nil to empty string
      else
        raise "Invalid key type: #{key.class}"
      end
    end
  end

  # Stub KeyReader to return a sequence of keys
  # Uses a queue that gets shifted on each read
  # After queue is exhausted, returns :enter up to MAX_READS times to prevent infinite loops
  MAX_READS = 50

  def stub_keys(*keys)
    queue = key_sequence(*keys)
    read_count = 0

    allow(Clack::Core::KeyReader).to receive(:read) do
      read_count += 1
      raise "Too many key reads (#{read_count}) - possible infinite loop" if read_count > MAX_READS

      queue.shift || KEYS[:enter]
    end
  end

  # Capture output to a StringIO
  def capture_output
    StringIO.new
  end

  # Strip ANSI codes for easier testing
  def strip_ansi(str)
    str.gsub(/\e\[[0-9;]*[mGKHJ]|\e\[\?25[hl]/, "")
  end
end

RSpec.configure do |config|
  config.include TestHelpers

  # Enable cursor escape sequences for testing
  config.before(:each) do
    Clack::Core::Cursor.enabled = true
  end

  config.after(:each) do
    Clack::Core::Cursor.enabled = nil
  end
end
