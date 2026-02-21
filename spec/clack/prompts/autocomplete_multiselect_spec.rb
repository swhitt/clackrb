# frozen_string_literal: true

RSpec.describe Clack::Prompts::AutocompleteMultiselect do
  let(:output) { StringIO.new }
  let(:options) { %w[apple banana cherry date elderberry] }

  subject { described_class.new(message: "Select fruits:", options: options, output: output) }

  it_behaves_like "a cancellable prompt"

  describe "#run" do
    it "allows selecting multiple items with space" do
      stub_keys(:space, :down, :space, :enter)
      result = subject.run

      expect(result).to contain_exactly("apple", "banana")
    end

    it "filters options as you type" do
      stub_keys("b", :space, :enter)
      result = subject.run

      expect(result).to eq(["banana"])
    end

    it "requires at least one selection by default" do
      stub_keys(:enter, :space, :enter)
      result = subject.run

      expect(result).to eq(["apple"])
      expect(output.string).to include("at least one")
    end

    it "allows empty selection when not required" do
      prompt = described_class.new(
        message: "Select:",
        options: options,
        required: false,
        output: output
      )
      stub_keys(:enter)
      result = prompt.run

      expect(result).to eq([])
    end

    it "toggles selection with space" do
      stub_keys(:space, :space, :enter)
      prompt = described_class.new(
        message: "Select:",
        options: options,
        required: false,
        output: output
      )
      result = prompt.run

      expect(result).to eq([])
    end

    it "toggles all with a key" do
      stub_keys("a", :enter)
      result = subject.run

      expect(result).to contain_exactly(*options)
    end

    it "inverts selection with i key" do
      stub_keys(:space, "i", :enter)
      result = subject.run

      expect(result).to contain_exactly("banana", "cherry", "date", "elderberry")
    end

    it "navigates with up/down" do
      stub_keys(:down, :down, :space, :enter)
      result = subject.run

      expect(result).to eq(["cherry"])
    end

    it "respects initial_values" do
      prompt = described_class.new(
        message: "Select:",
        options: options,
        initial_values: %w[banana date],
        output: output
      )
      stub_keys(:enter)
      result = prompt.run

      expect(result).to contain_exactly("banana", "date")
    end

    it "handles hash options with hints" do
      hash_options = [
        {value: "a", label: "Apple", hint: "fruit"},
        {value: "b", label: "Banana", hint: "tropical"}
      ]
      prompt = described_class.new(
        message: "Select:",
        options: hash_options,
        output: output
      )
      stub_keys(:space, :enter)
      result = prompt.run

      expect(result).to eq(["a"])
    end

    it "shows no matches message when filter returns empty" do
      stub_keys("xyz", :backspace, :backspace, :backspace, :space, :enter)
      subject.run

      expect(output.string).to include("No matches")
    end

    it "shows match count when filtering" do
      stub_keys("c", "h", :space, :enter) # Type 'ch' to filter to cherry
      subject.run

      expect(output.string).to include("match")
    end

    it "shows selected labels in final frame" do
      stub_keys(:space, :down, :space, :enter)
      subject.run

      expect(output.string).to include("apple, banana")
    end
  end

  describe "custom filter" do
    def create_prompt(**opts)
      described_class.new(
        message: "Select fruits:",
        options: options,
        output: output,
        **opts
      )
    end

    it "uses the custom filter proc" do
      starts_with = ->(opt, query) { opt[:label].start_with?(query) }
      stub_keys("b", :space, :enter)
      prompt = create_prompt(filter: starts_with)
      result = prompt.run

      expect(result).to eq(["banana"])
    end

    it "receives the raw query without downcasing" do
      received_queries = []
      spy_filter = ->(opt, query) {
        received_queries << query
        opt[:label].downcase.include?(query.downcase)
      }
      stub_keys("Ban", :space, :enter)
      prompt = create_prompt(filter: spy_filter)
      prompt.run

      expect(received_queries).to include("Ban")
    end

    it "falls back to default behavior when filter is nil" do
      stub_keys("b", :space, :enter)
      prompt = create_prompt(filter: nil)
      result = prompt.run

      expect(result).to eq(["banana"])
    end
  end
end
