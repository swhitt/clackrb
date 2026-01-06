# frozen_string_literal: true

RSpec.describe Clack::Prompts::Confirm do
  let(:output) { StringIO.new }
  subject { described_class.new(message: "Continue?", output: output) }

  it_behaves_like "a cancellable prompt"

  describe "#run" do
    it "defaults to true" do
      stub_keys(:enter)
      result = subject.run

      expect(result).to be true
    end

    it "respects initial_value of false" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Continue?",
        initial_value: false,
        output: output
      )
      result = prompt.run

      expect(result).to be false
    end

    it "right arrow selects false" do
      stub_keys(:right, :enter)
      prompt = described_class.new(message: "Continue?", output: output)
      result = prompt.run

      expect(result).to be false
    end

    it "left arrow selects true" do
      stub_keys(:right, :left, :enter)
      prompt = described_class.new(message: "Continue?", output: output)
      result = prompt.run

      expect(result).to be true
    end

    it "down arrow selects false" do
      stub_keys(:down, :enter)
      prompt = described_class.new(message: "Continue?", output: output)
      result = prompt.run

      expect(result).to be false
    end

    it "up arrow selects true" do
      stub_keys(:down, :up, :enter)
      prompt = described_class.new(message: "Continue?", output: output)
      result = prompt.run

      expect(result).to be true
    end

    it "y key selects true" do
      stub_keys(:right, "y", :enter)
      prompt = described_class.new(message: "Continue?", output: output)
      result = prompt.run

      expect(result).to be true
    end

    it "Y key selects true" do
      stub_keys(:right, "Y", :enter)
      prompt = described_class.new(message: "Continue?", output: output)
      result = prompt.run

      expect(result).to be true
    end

    it "n key selects false" do
      stub_keys("n", :enter)
      prompt = described_class.new(message: "Continue?", output: output)
      result = prompt.run

      expect(result).to be false
    end

    it "N key selects false" do
      stub_keys("N", :enter)
      prompt = described_class.new(message: "Continue?", output: output)
      result = prompt.run

      expect(result).to be false
    end

    it "uses custom active label" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Continue?",
        active: "Yep",
        output: output
      )
      prompt.run

      expect(output.string).to include("Yep")
    end

    it "uses custom inactive label" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Continue?",
        inactive: "Nope",
        output: output
      )
      prompt.run

      expect(output.string).to include("Nope")
    end

    it "shows selected value on submit" do
      stub_keys(:enter)
      prompt = described_class.new(message: "Continue?", output: output)
      prompt.run

      expect(output.string).to include("Yes")
    end

    it "shows strikethrough on cancel" do
      stub_keys(:escape)
      prompt = described_class.new(message: "Continue?", output: output)
      prompt.run

      # Cancel state reached
      expect(prompt.state).to eq(:cancel)
    end

    it "ignores unknown characters" do
      stub_keys("x", "z", :enter)
      prompt = described_class.new(message: "Continue?", output: output)
      result = prompt.run

      expect(result).to be true # Default unchanged
    end

    it "handles nil key gracefully" do
      stub_keys(nil, :enter)
      prompt = described_class.new(message: "Continue?", output: output)
      result = prompt.run

      expect(result).to be true
    end
  end
end
