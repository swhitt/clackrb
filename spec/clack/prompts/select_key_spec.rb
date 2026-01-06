RSpec.describe Clack::Prompts::SelectKey do
  let(:output) { StringIO.new }
  let(:input) { StringIO.new }
  let(:options) do
    [
      {value: "create", label: "Create new", key: "c"},
      {value: "open", label: "Open existing", key: "o"},
      {value: "quit", label: "Quit", key: "q"}
    ]
  end
  subject { described_class.new(message: "Choose an action", options: options, input: input, output: output) }

  def create_prompt(**opts)
    described_class.new(
      message: "Choose an action",
      options: options,
      input: input,
      output: output,
      **opts
    )
  end

  it_behaves_like "a cancellable prompt"

  describe "#run" do
    it "returns selected value when key pressed" do
      stub_keys("c")
      result = subject.run

      expect(result).to eq("create")
    end

    it "is case insensitive" do
      stub_keys("O")
      result = subject.run

      expect(result).to eq("open")
    end

    it "ignores non-matching keys and waits for valid key" do
      stub_keys("x", "y", "z", "q")
      result = subject.run

      expect(result).to eq("quit")
    end

    it "shows selected option in final frame" do
      stub_keys("o")
      prompt = create_prompt
      prompt.run

      expect(output.string).to include("Open existing")
    end

    it "shows strikethrough on cancel" do
      stub_keys(:escape)
      prompt = create_prompt
      prompt.run

      expect(output.string).to include(Clack::Symbols::S_STEP_CANCEL)
    end

    it "renders message in output" do
      stub_keys("c")
      prompt = create_prompt
      prompt.run

      expect(output.string).to include("Choose an action")
    end

    it "displays all options with keys" do
      stub_keys("c")
      prompt = create_prompt
      prompt.run

      expect(output.string).to include("[c]")
      expect(output.string).to include("Create new")
      expect(output.string).to include("[o]")
      expect(output.string).to include("Open existing")
      expect(output.string).to include("[q]")
      expect(output.string).to include("Quit")
    end
  end
end
