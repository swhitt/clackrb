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

# Shared examples for warning validation behavior
# Requires:
#   - let(:output) { StringIO.new }
#   - let(:valid_input) - keys that produce valid input (e.g., "test")
#   - let(:warning_input) - keys that trigger warning (e.g., "warn")
#   - let(:warning_validator) - validator that returns Warning for warning_input
RSpec.shared_examples "a prompt with warning validation" do
  context "with warning validation" do
    it "shows warning and allows confirmation with Enter" do
      stub_keys(*warning_input, :enter, :enter)
      prompt = described_class.new(
        message: "Input?",
        validate: warning_validator,
        output: output
      )
      prompt.run

      expect(output.string).to include("Are you sure?")
      expect(output.string).to include("Press Enter to confirm")
    end

    it "can cancel from warning state" do
      stub_keys(*warning_input, :enter, :escape)
      prompt = described_class.new(
        message: "Input?",
        validate: warning_validator,
        output: output
      )
      result = prompt.run

      expect(Clack.cancel?(result)).to be true
    end

    it "distinguishes warnings from errors" do
      stub_keys(:enter, *valid_input, :enter, :enter)
      prompt = described_class.new(
        message: "Input?",
        validate: lambda { |val|
          return "Required" if val.to_s.empty?

          Clack::Warning.new("Short input") if val.to_s.length < 3
        },
        output: output
      )
      prompt.run

      expect(output.string).to include("Required")
      expect(output.string).to include("Short input")
    end
  end
end

# Shared examples for text-input prompts with warning validation
# Requires same as "a prompt with warning validation" plus:
#   - let(:edit_keys) - keys that edit the input during warning (e.g., [:backspace, "ok"])
RSpec.shared_examples "a text prompt with warning validation" do
  it_behaves_like "a prompt with warning validation"

  context "with warning validation" do
    it "clears warning on edit and re-validates" do
      stub_keys(*warning_input, :enter, *edit_keys, :enter)
      prompt = described_class.new(
        message: "Input?",
        validate: ->(val) { Clack::Warning.new("Bad value") if val.to_s.match?(/bad|warn/) },
        output: output
      )
      prompt.run

      expect(output.string).to include("Bad value")
    end

    it "appends input typed during warning state" do
      stub_keys("a", :enter, "bc", :enter)
      prompt = described_class.new(
        message: "Input?",
        validate: ->(v) { Clack::Warning.new("Short") if v.to_s.length < 3 },
        output: output
      )
      result = prompt.run

      expect(result).to eq("abc")
    end
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
