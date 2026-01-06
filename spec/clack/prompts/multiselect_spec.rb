# frozen_string_literal: true

RSpec.describe Clack::Prompts::Multiselect do
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
    it "requires at least one selection by default" do
      stub_keys(:enter, :space, :enter)
      result = subject.run

      expect(result).to eq(["a"])
    end

    it "shows error when no selection and required" do
      stub_keys(:enter, :space, :enter)
      subject.run

      expect(output.string).to include("select at least one")
    end

    it "allows empty selection when not required" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Choose:",
        options: options,
        required: false,
        output: output
      )
      result = prompt.run

      expect(result).to eq([])
    end

    it "space toggles selection" do
      stub_keys(:space, :down, :space, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to contain_exactly("a", "b")
    end

    it "space deselects already selected" do
      stub_keys(:space, :space, :down, :space, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to eq(["b"])
    end

    it "down arrow moves cursor" do
      stub_keys(:down, :space, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to eq(["b"])
    end

    it "up arrow moves cursor" do
      stub_keys(:down, :down, :up, :space, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to eq(["b"])
    end

    it "wraps from last to first" do
      stub_keys(:down, :down, :down, :space, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to eq(["a"])
    end

    it "wraps from first to last" do
      stub_keys(:up, :space, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to eq(["c"])
    end

    it "'a' key toggles all" do
      stub_keys("a", :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to contain_exactly("a", "b", "c")
    end

    it "'a' key deselects all when all selected" do
      stub_keys("a", "a", :space, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to eq(["a"])  # Only first selected after toggle all off then space
    end

    it "'A' key also toggles all (case insensitive)" do
      stub_keys("A", :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to contain_exactly("a", "b", "c")
    end

    it "'i' key inverts selection" do
      stub_keys(:space, "i", :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to contain_exactly("b", "c")
    end

    it "'I' key also inverts (case insensitive)" do
      stub_keys(:space, "I", :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      result = prompt.run

      expect(result).to contain_exactly("b", "c")
    end

    it "respects initial_values" do
      stub_keys(:enter)
      prompt = described_class.new(
        message: "Choose:",
        options: options,
        initial_values: %w[b c],
        output: output
      )
      result = prompt.run

      expect(result).to contain_exactly("b", "c")
    end

    it "handles simple value options" do
      stub_keys(:space, :enter)
      prompt = described_class.new(
        message: "Choose:",
        options: %w[one two three],
        output: output
      )
      result = prompt.run

      expect(result).to eq(["one"])
    end

    it "skips disabled options" do
      opts = [
        {value: "a", label: "A", disabled: true},
        {value: "b", label: "B"},
        {value: "c", label: "C"}
      ]
      stub_keys(:space, :enter)
      prompt = described_class.new(message: "Choose:", options: opts, output: output)
      result = prompt.run

      expect(result).to eq(["b"])  # Skips disabled first option
    end

    it "cannot toggle disabled options" do
      opts = [
        {value: "a", label: "A"},
        {value: "b", label: "B", disabled: true},
        {value: "c", label: "C"}
      ]
      # space a, down to c (skip b), space c, enter
      stub_keys(:space, :down, :space, :enter)
      prompt = described_class.new(message: "Choose:", options: opts, output: output)
      result = prompt.run

      expect(result).to contain_exactly("a", "c") # b is skipped
    end

    it "toggle all ignores disabled options" do
      opts = [
        {value: "a", label: "A"},
        {value: "b", label: "B", disabled: true},
        {value: "c", label: "C"}
      ]
      stub_keys("a", :enter)
      prompt = described_class.new(message: "Choose:", options: opts, output: output)
      result = prompt.run

      expect(result).to contain_exactly("a", "c")
    end

    it "invert ignores disabled options" do
      opts = [
        {value: "a", label: "A"},
        {value: "b", label: "B", disabled: true},
        {value: "c", label: "C"}
      ]
      stub_keys(:space, "i", :enter)
      prompt = described_class.new(message: "Choose:", options: opts, output: output)
      result = prompt.run

      expect(result).to eq(["c"])
    end

    it "supports cursor_at option" do
      stub_keys(:space, :enter)
      prompt = described_class.new(
        message: "Choose:",
        options: options,
        cursor_at: "b",
        output: output
      )
      result = prompt.run

      expect(result).to eq(["b"])
    end

    it "cursor_at falls back when pointing to disabled" do
      opts = [
        {value: "a", label: "A"},
        {value: "b", label: "B", disabled: true}
      ]
      stub_keys(:space, :enter)
      prompt = described_class.new(
        message: "Choose:",
        options: opts,
        cursor_at: "b",
        output: output
      )
      result = prompt.run

      expect(result).to eq(["a"])
    end

    it "supports max_items for scrolling" do
      many_opts = (1..10).map { |i| {value: i, label: "Option #{i}"} }
      stub_keys(:down, :down, :space, :enter)
      prompt = described_class.new(
        message: "Choose:",
        options: many_opts,
        max_items: 3,
        output: output
      )
      result = prompt.run

      expect(result).to eq([3])
    end

    it "scrolls up when navigating above visible window" do
      many_opts = (1..10).map { |i| {value: i, label: "Option #{i}"} }
      # Go down 5 times to scroll down, then up 3 times to scroll back up, select item 3
      stub_keys(:down, :down, :down, :down, :down, :up, :up, :up, :space, :enter)
      prompt = described_class.new(
        message: "Choose:",
        options: many_opts,
        max_items: 3,
        output: output
      )
      result = prompt.run

      expect(result).to eq([3])
    end

    it "shows selected labels in final frame" do
      stub_keys(:space, :down, :space, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      prompt.run

      expect(output.string).to include("Option A")
      expect(output.string).to include("Option B")
    end

    it "clears error state on action" do
      stub_keys(:enter, :space, :enter)
      prompt = described_class.new(message: "Choose:", options: options, output: output)
      prompt.run

      # After the error, should be in submit state
      expect(prompt.state).to eq(:submit)
    end

    it "stays on same position when all options disabled" do
      opts = [
        {value: "a", label: "A", disabled: true},
        {value: "b", label: "B", disabled: true}
      ]
      stub_keys(:down, :up, :escape)
      prompt = described_class.new(
        message: "Choose:",
        options: opts,
        required: false,
        output: output
      )
      result = prompt.run

      # User can only cancel when all options are disabled
      expect(Clack.cancel?(result)).to be true
    end

    it "handles unicode in option labels" do
      opts = [
        {value: "jp", label: "日本語オプション"},
        {value: "emoji", label: "Emoji 🎉"},
        {value: "mix", label: "Mixed 混合"}
      ]
      stub_keys(:space, :down, :space, :enter)
      prompt = described_class.new(message: "Choose:", options: opts, output: output)
      result = prompt.run

      expect(result).to contain_exactly("jp", "emoji")
      expect(output.string).to include("日本語")
      expect(output.string).to include("🎉")
    end

    it "renders message in output" do
      stub_keys(:space, :enter)
      prompt = described_class.new(message: "Select items:", options: options, output: output)
      prompt.run

      expect(output.string).to include("Select items:")
    end
  end
end
