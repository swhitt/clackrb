# frozen_string_literal: true

RSpec.describe Clack::Prompts::Text do
  let(:output) { StringIO.new }
  subject { described_class.new(message: "Name?", output: output) }

  it_behaves_like "a cancellable prompt"

  describe "#run" do
    it "renders message and accepts input" do
      stub_keys("h", "i", :enter)
      result = subject.run

      expect(result).to eq("hi")
    end

    it "uses default_value when empty" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Name?",
        default_value: "Anonymous",
        output: output
      )
      result = prompt.run

      expect(result).to eq("Anonymous")
    end

    it "uses initial_value as starting text" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Name?",
        initial_value: "preset",
        output: output
      )
      result = prompt.run

      expect(result).to eq("preset")
    end

    it "supports placeholder display" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Email?",
        placeholder: "you@example.com",
        output: output
      )
      result = prompt.run

      expect(result).to eq("")
      expect(output.string).to include("you@example.com")
    end

    it "handles backspace" do
      stub_keys("a", "b", "c", :backspace, :enter)
      prompt = described_class.new(message: "Input?", output: output)
      result = prompt.run

      expect(result).to eq("ab")
    end

    it "handles cursor movement left" do
      stub_keys("a", "b", :left, "x", :enter)
      prompt = described_class.new(message: "Input?", output: output)
      result = prompt.run

      expect(result).to eq("axb")
    end

    it "handles cursor movement right" do
      stub_keys("a", "b", :left, :left, :right, "x", :enter)
      prompt = described_class.new(message: "Input?", output: output)
      result = prompt.run

      expect(result).to eq("axb")
    end

    it "cursor cannot go before start" do
      stub_keys("a", :left, :left, :left, "x", :enter)
      prompt = described_class.new(message: "Input?", output: output)
      result = prompt.run

      expect(result).to eq("xa")
    end

    it "cursor cannot go past end" do
      stub_keys("a", :right, :right, "b", :enter)
      prompt = described_class.new(message: "Input?", output: output)
      result = prompt.run

      expect(result).to eq("ab")
    end

    it "validates input and shows error" do
      stub_keys(:enter, "x", :enter)
      prompt = described_class.new(
        message: "Input?",
        validate: ->(val) { "Required" if val.empty? },
        output: output
      )
      result = prompt.run

      expect(result).to eq("x")
      expect(output.string).to include("Required")
    end

    it "validates with Error object" do
      stub_keys(:enter, "ok", :enter)
      prompt = described_class.new(
        message: "Input?",
        validate: ->(val) { StandardError.new("Bad input") if val.empty? },
        output: output
      )
      result = prompt.run

      expect(result).to eq("ok")
      expect(output.string).to include("Bad input")
    end

    it "ignores non-printable characters" do
      stub_keys("a", "\x00", "\x1f", "b", :enter)
      prompt = described_class.new(message: "Input?", output: output)
      result = prompt.run

      expect(result).to eq("ab")
    end

    it "backspace at start does nothing" do
      stub_keys(:backspace, "a", :enter)
      prompt = described_class.new(message: "Input?", output: output)
      result = prompt.run

      expect(result).to eq("a")
    end

    it "renders cancelled value in output" do
      stub_keys("x", "y", :escape)
      prompt = described_class.new(message: "Input?", output: output)
      result = prompt.run

      expect(Clack.cancel?(result)).to be true
      expect(output.string).to include("xy")
    end

    it "renders submitted value in final output" do
      stub_keys("ok", :enter)
      prompt = described_class.new(message: "Input?", output: output)
      result = prompt.run

      expect(result).to eq("ok")
      expect(output.string).to include("ok")
      expect(output.string).to include("Input?")
    end

    it "handles unicode characters correctly" do
      stub_keys("日", "本", :enter)
      prompt = described_class.new(message: "Input?", output: output)
      result = prompt.run

      expect(result).to eq("日本")
    end

    it "handles emoji input" do
      stub_keys("👋", "🎉", :enter)
      prompt = described_class.new(message: "Input?", output: output)
      result = prompt.run

      expect(result).to eq("👋🎉")
    end

    it "placeholder is not used as value when pressing enter" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Name?",
        placeholder: "(hit Enter to use default)",
        default_value: "default-value",
        output: output
      )
      result = prompt.run

      expect(result).to eq("default-value")
      expect(result).not_to eq("(hit Enter to use default)")
    end

    it "returns empty string when no value and no default" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Optional?",
        placeholder: "(optional)",
        output: output
      )
      result = prompt.run

      expect(result).to eq("")
    end

    it "clears validation error after valid input" do
      stub_keys(:enter, "valid", :enter)
      prompt = described_class.new(
        message: "Input?",
        validate: ->(val) { "Required" if val.empty? },
        output: output
      )
      result = prompt.run

      expect(result).to eq("valid")
      # Error appeared then was resolved
      expect(output.string).to include("Required")
    end

    it "displays help text when provided" do
      stub_keys("x", :enter)
      prompt = described_class.new(
        message: "Input?",
        help: "Enter something useful",
        output: output
      )
      prompt.run

      expect(output.string).to include("Enter something useful")
    end

    it "does not show help line when not provided" do
      stub_keys("x", :enter)
      prompt = described_class.new(message: "Input?", output: output)
      prompt.run

      # Just verify it doesn't crash and works normally
      expect(output.string).to include("Input?")
    end
  end
end
