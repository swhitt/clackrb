RSpec.describe Clack::Prompts::Select do
  let(:output) { StringIO.new }
  let(:options) do
    [
      {value: "a", label: "Option A"},
      {value: "b", label: "Option B"},
      {value: "c", label: "Option C"}
    ]
  end
  subject { described_class.new(message: "Choose:", options: options, output: output) }

  it_behaves_like "a cancellable prompt"

  describe "#run" do
    it "selects first option by default" do
      stub_keys(:enter)
      result = subject.run

      expect(result).to eq("a")
    end

    it "down arrow selects next option" do
      stub_keys(:down, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to eq("b")
    end

    it "up arrow selects previous option" do
      stub_keys(:down, :down, :up, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to eq("b")
    end

    it "right arrow selects next option" do
      stub_keys(:right, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to eq("b")
    end

    it "left arrow selects previous option" do
      stub_keys(:down, :left, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to eq("a")
    end

    it "wraps from last to first" do
      stub_keys(:down, :down, :down, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to eq("a")
    end

    it "wraps from first to last" do
      stub_keys(:up, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to eq("c")
    end

    it "respects initial_value" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Choose:",
        options: options,
        initial_value: "b",
        output: output
      )
      result = prompt.run

      expect(result).to eq("b")
    end

    it "renders option labels" do
      stub_keys(:enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      prompt.run

      expect(output.string).to include("Option A")
      expect(output.string).to include("Option B")
      expect(output.string).to include("Option C")
    end

    it "renders option hints" do
      opts = [{value: "a", label: "A", hint: "recommended"}]
      stub_keys(:enter)
      prompt = described_class.new(message: "Choose:", options: opts, output: output)
      prompt.run

      expect(output.string).to include("recommended")
    end

    it "handles simple value options" do
      stub_keys(:down, :enter)
      prompt = described_class.new(
        message: "Choose:",
        options: ["one", "two", "three"],
        output: output
      )
      result = prompt.run

      expect(result).to eq("two")
    end

    it "skips disabled options" do
      opts = [
        {value: "a", label: "A", disabled: true},
        {value: "b", label: "B"},
        {value: "c", label: "C"}
      ]
      stub_keys(:enter)
      prompt = described_class.new(message: "Choose:", options: opts, output: output)
      result = prompt.run

      expect(result).to eq("b")  # Skips disabled first option
    end

    it "skips disabled options when navigating" do
      opts = [
        {value: "a", label: "A"},
        {value: "b", label: "B", disabled: true},
        {value: "c", label: "C"}
      ]
      stub_keys(:down, :enter)
      prompt = described_class.new(message: "Choose:", options: opts, output: output)
      result = prompt.run

      expect(result).to eq("c")  # Skips disabled middle option
    end

    it "cannot submit disabled option" do
      opts = [
        {value: "a", label: "A", disabled: true},
        {value: "b", label: "B"}
      ]
      # First enter is ignored because first option is disabled
      # Navigation moves to B, second enter submits
      stub_keys(:enter, :down, :enter)
      prompt = described_class.new(message: "Choose:", options: opts, output: output)
      result = prompt.run

      expect(result).to eq("b")
    end

    it "handles initial_value pointing to disabled option" do
      opts = [
        {value: "a", label: "A", disabled: true},
        {value: "b", label: "B"},
        {value: "c", label: "C"}
      ]
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Choose:",
        options: opts,
        initial_value: "a",
        output: output
      )
      result = prompt.run

      expect(result).to eq("b")  # Falls back to first enabled
    end

    it "supports max_items for scrolling" do
      many_opts = (1..10).map { |i| {value: i, label: "Option #{i}"} }
      stub_keys(:down, :down, :down, :enter)
      prompt = described_class.new(
        message: "Choose:",
        options: many_opts,
        max_items: 3,
        output: output
      )
      result = prompt.run

      expect(result).to eq(4)
    end

    it "scrolls up when navigating above visible window" do
      many_opts = (1..10).map { |i| {value: i, label: "Option #{i}"} }
      # Go down 5 times to scroll down, then up 3 times to scroll back up
      stub_keys(:down, :down, :down, :down, :down, :up, :up, :up, :enter)
      prompt = described_class.new(
        message: "Choose:",
        options: many_opts,
        max_items: 3,
        output: output
      )
      result = prompt.run

      expect(result).to eq(3)
    end

    it "shows selected label in final frame" do
      stub_keys(:down, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      prompt.run

      expect(output.string).to include("Option B")
    end

    it "handles all options disabled by allowing cancel" do
      opts = [
        {value: "a", label: "A", disabled: true},
        {value: "b", label: "B", disabled: true}
      ]
      stub_keys(:down, :up, :escape)
      prompt = described_class.new(message: "Choose:", options: opts, output: output)
      result = prompt.run

      # User can only cancel when all options are disabled
      expect(Clack.cancel?(result)).to be true
    end

    it "handles unicode in option labels" do
      opts = [
        {value: "jp", label: "日本語"},
        {value: "emoji", label: "Option 👍"}
      ]
      stub_keys(:down, :enter)
      prompt = described_class.new(message: "Choose:", options: opts, output: output)
      result = prompt.run

      expect(result).to eq("emoji")
      expect(output.string).to include("日本語")
      expect(output.string).to include("👍")
    end

    it "renders message in output" do
      stub_keys(:enter)
      prompt = described_class.new(message: "Pick one:", options: options, output: output)
      prompt.run

      expect(output.string).to include("Pick one:")
    end
  end
end
