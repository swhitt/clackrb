# frozen_string_literal: true

RSpec.describe Clack::Prompts::Autocomplete do
  let(:output) { StringIO.new }
  subject do
    described_class.new(message: "Pick a fruit", options: %w[apple banana cherry], output: output)
  end

  def create_prompt(options: %w[apple banana cherry], **opts)
    described_class.new(
      message: "Pick a fruit",
      options: options,
      output: output,
      **opts
    )
  end

  it_behaves_like "a cancellable prompt"

  describe "#run" do
    it "returns selected value on enter" do
      stub_keys(:enter)
      result = subject.run

      expect(result).to eq("apple")
    end

    it "filters and selects filtered option" do
      stub_keys("b", :enter)
      result = subject.run

      expect(result).to eq("banana")
    end

    it "navigates with arrow keys" do
      stub_keys(:down, :enter)
      result = subject.run

      expect(result).to eq("banana")
    end

    it "wraps selection from last to first" do
      stub_keys(:down, :down, :down, :enter)
      result = subject.run

      expect(result).to eq("apple")
    end

    it "wraps selection from first to last" do
      stub_keys(:up, :enter)
      result = subject.run

      expect(result).to eq("cherry")
    end

    it "shows error when no matching option on submit" do
      stub_keys("xyz", :enter, :backspace, :backspace, :backspace, :enter)
      prompt = create_prompt
      prompt.run

      expect(output.string).to include("No matching option")
    end

    it "shows selected label in final frame" do
      stub_keys(:down, :enter)
      prompt = create_prompt
      prompt.run

      expect(output.string).to include("banana")
    end

    it "shows strikethrough on cancel" do
      stub_keys("app", :escape)
      prompt = create_prompt
      prompt.run

      expect(output.string).to include(Clack::Symbols::S_STEP_CANCEL)
    end

    it "handles placeholder display" do
      stub_keys(:enter)
      prompt = create_prompt(placeholder: "Type to search...")
      prompt.run

      expect(output.string).to include("Type to search")
    end

    it "handles backspace to unfilter" do
      stub_keys("ban", :backspace, :backspace, :backspace, :enter)
      result = subject.run

      expect(result).to eq("apple")
    end

    it "handles hash options with label and value" do
      prompt = create_prompt(options: [
        {value: "a", label: "Option A"},
        {value: "b", label: "Option B"}
      ])
      stub_keys(:down, :enter)
      result = prompt.run

      expect(result).to eq("b")
      expect(output.string).to include("Option B")
    end

    it "displays all options initially" do
      stub_keys(:enter)
      prompt = create_prompt
      prompt.run

      expect(output.string).to include("apple")
      expect(output.string).to include("banana")
      expect(output.string).to include("cherry")
    end

    it "filters options as user types" do
      stub_keys("ch", :enter)
      prompt = create_prompt
      result = prompt.run

      expect(result).to eq("cherry")
    end

    it "typing 'j' filters instead of navigating down" do
      # 'j' is a vim alias for :down — should be treated as text input in autocomplete
      stub_keys("j", :backspace, :enter)
      result = subject.run

      expect(result).to eq("apple")
    end

    it "typing 'k' filters instead of navigating up" do
      # 'k' is a vim alias for :up — should be treated as text input in autocomplete
      stub_keys("k", :backspace, :enter)
      result = subject.run

      expect(result).to eq("apple")
    end

    it "typing 'h' filters instead of acting as vim left" do
      stub_keys("h", :backspace, :enter)
      result = subject.run

      expect(result).to eq("apple")
    end

    it "typing 'l' filters instead of acting as vim right" do
      stub_keys("l", :backspace, :enter)
      result = subject.run

      expect(result).to eq("apple")
    end

    it "shows cancel state when filter has no results" do
      stub_keys("xyz", :escape)
      prompt = create_prompt
      prompt.run

      expect(output.string).to include(Clack::Symbols::S_STEP_CANCEL)
    end
  end

  describe "custom filter" do
    it "uses the custom filter proc instead of default matching" do
      # Only match options whose label starts with the query (case-sensitive)
      starts_with_filter = ->(opt, query) { opt[:label].start_with?(query) }
      stub_keys("app", :enter)
      prompt = create_prompt(filter: starts_with_filter)
      result = prompt.run

      expect(result).to eq("apple")
    end

    it "excludes options that do not satisfy the custom filter" do
      # Only match labels starting with the query; "a" matches "apple" but not "banana"
      starts_with_filter = ->(opt, query) { opt[:label].start_with?(query) }
      stub_keys("b", :enter)
      prompt = create_prompt(filter: starts_with_filter)
      result = prompt.run

      expect(result).to eq("banana")
    end

    it "shows error when custom filter matches nothing" do
      reject_all = ->(_opt, _query) { false }
      stub_keys("x", :enter, :escape)
      prompt = create_prompt(filter: reject_all)
      prompt.run

      expect(output.string).to include("No matching option")
    end

    it "receives the raw query without downcasing" do
      received_queries = []
      spy_filter = ->(opt, query) {
        received_queries << query
        opt[:label].downcase.include?(query.downcase)
      }
      stub_keys("App", :enter)
      prompt = create_prompt(filter: spy_filter)
      prompt.run

      # The filter should receive "A", "Ap", "App" -- not downcased
      expect(received_queries).to include("App")
    end

    it "receives the full option hash" do
      opts_with_hints = [
        {value: "a", label: "Apple", hint: "fruit"},
        {value: "b", label: "Banana", hint: "fruit"},
        {value: "c", label: "Carrot", hint: "vegetable"}
      ]
      # Filter by hint field
      hint_filter = ->(opt, _query) { opt[:hint] == "vegetable" }
      stub_keys("x", :enter)
      prompt = create_prompt(options: opts_with_hints, filter: hint_filter)
      result = prompt.run

      expect(result).to eq("c")
    end

    it "falls back to default behavior when filter is nil" do
      stub_keys("b", :enter)
      prompt = create_prompt(filter: nil)
      result = prompt.run

      expect(result).to eq("banana")
    end
  end
end
