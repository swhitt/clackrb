# frozen_string_literal: true

RSpec.describe Clack do
  let(:output) { StringIO.new }

  it "has a version number" do
    expect(Clack::VERSION).not_to be_nil
  end

  describe "CANCEL" do
    it "has a readable inspect" do
      expect(Clack::CANCEL.inspect).to eq("Clack::CANCEL")
    end

    it "is frozen" do
      expect(Clack::CANCEL).to be_frozen
    end
  end

  describe ".cancel?" do
    it "returns true for CANCEL" do
      expect(Clack.cancel?(Clack::CANCEL)).to be true
    end

    it "returns false for other values" do
      expect(Clack.cancel?("hello")).to be false
      expect(Clack.cancel?(nil)).to be false
      expect(Clack.cancel?(false)).to be false
    end

    it "uses identity check not equality" do
      fake_cancel = Object.new
      expect(Clack.cancel?(fake_cancel)).to be false
    end
  end

  describe ".intro" do
    it "outputs intro with title" do
      Clack.intro("test-app", output: output)
      expect(output.string).to include("test-app")
      expect(output.string).to include(Clack::Symbols::S_BAR_START)
    end

    it "outputs only start symbol and title" do
      Clack.intro("test", output: output)
      lines = output.string.lines
      expect(lines.length).to eq(1)
      expect(lines[0]).to include(Clack::Symbols::S_BAR_START)
    end

    it "works without title" do
      Clack.intro(nil, output: output)
      expect(output.string).to include(Clack::Symbols::S_BAR_START)
    end
  end

  describe ".outro" do
    it "outputs outro with message" do
      Clack.outro("Done!", output: output)
      expect(output.string).to include("Done!")
      expect(output.string).to include(Clack::Symbols::S_BAR_END)
    end

    it "outputs bar before message" do
      Clack.outro("Done!", output: output)
      expect(output.string).to include(Clack::Symbols::S_BAR)
    end

    it "adds trailing newline" do
      Clack.outro("Done!", output: output)
      expect(output.string).to end_with("\n")
    end

    it "works without message" do
      Clack.outro(nil, output: output)
      expect(output.string).to include(Clack::Symbols::S_BAR_END)
    end
  end

  describe ".cancel" do
    it "outputs cancel message" do
      Clack.cancel("Cancelled", output: output)
      expect(output.string).to include("Cancelled")
      # NOTE: Colors are disabled in tests since stdout is not a TTY
    end

    it "outputs bar before message" do
      Clack.cancel("Cancelled", output: output)
      expect(output.string).to include(Clack::Symbols::S_BAR)
    end

    it "works without message" do
      Clack.cancel(nil, output: output)
      expect(output.string).to include(Clack::Symbols::S_BAR_END)
    end
  end

  describe ".text" do
    it "creates and runs a Text prompt" do
      stub_keys("hi", :enter)
      result = Clack.text(message: "Name?", output: output)
      expect(result).to eq("hi")
    end

    it "passes options to Text prompt" do
      stub_keys(:enter)
      result = Clack.text(message: "Name?", default_value: "default", output: output)
      expect(result).to eq("default")
    end
  end

  describe ".password" do
    it "creates and runs a Password prompt" do
      stub_keys("secret", :enter)
      result = Clack.password(message: "Password:", output: output)
      expect(result).to eq("secret")
    end
  end

  describe ".confirm" do
    it "creates and runs a Confirm prompt" do
      stub_keys(:enter)
      result = Clack.confirm(message: "Continue?", output: output)
      expect(result).to be true
    end

    it "passes options to Confirm prompt" do
      stub_keys(:enter)
      result = Clack.confirm(message: "Continue?", initial_value: false, output: output)
      expect(result).to be false
    end
  end

  describe ".select" do
    it "creates and runs a Select prompt" do
      stub_keys(:enter)
      result = Clack.select(message: "Choose:", options: %w[a b], output: output)
      expect(result).to eq("a")
    end
  end

  describe ".multiselect" do
    it "creates and runs a Multiselect prompt" do
      stub_keys(:space, :enter)
      result = Clack.multiselect(message: "Choose:", options: %w[a b], output: output)
      expect(result).to eq(["a"])
    end

    it "passes required option" do
      stub_keys(:enter)
      result = Clack.multiselect(message: "Choose:", options: %w[a b], required: false, output: output)
      expect(result).to eq([])
    end
  end

  describe ".spinner" do
    it "creates a Spinner instance" do
      spinner = Clack.spinner(output: output)
      expect(spinner).to be_a(Clack::Prompts::Spinner)
    end
  end

  describe ".log" do
    it "returns the Log module" do
      expect(Clack.log).to eq(Clack::Log)
    end
  end

  describe ".note" do
    it "renders a note" do
      Clack.note("Hello", output: output)
      expect(output.string).to include("Hello")
    end

    it "renders a note with title" do
      Clack.note("Hello", title: "Info", output: output)
      expect(output.string).to include("Info")
      expect(output.string).to include("Hello")
    end
  end
end
