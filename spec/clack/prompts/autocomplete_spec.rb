RSpec.describe Clack::Prompts::Autocomplete do
  let(:output) { StringIO.new }
  let(:input) { StringIO.new }
  subject { described_class.new(message: "Pick a fruit", options: %w[apple banana cherry], input: input, output: output) }

  def create_prompt(options: %w[apple banana cherry], **opts)
    described_class.new(
      message: "Pick a fruit",
      options: options,
      input: input,
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
  end
end
