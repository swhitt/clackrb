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

  describe "Warning" do
    it "stores the message" do
      warning = Clack::Warning.new("Watch out!")
      expect(warning.message).to eq("Watch out!")
    end

    it "converts to string" do
      warning = Clack::Warning.new("Be careful")
      expect(warning.to_s).to eq("Be careful")
    end

    it "handles empty message" do
      warning = Clack::Warning.new("")
      expect(warning.message).to eq("")
      expect(warning.to_s).to eq("")
    end

    it "handles nil message" do
      warning = Clack::Warning.new(nil)
      expect(warning.message).to be_nil
      expect(warning.to_s).to be_nil
    end
  end

  describe ".warning" do
    it "creates a Warning object" do
      warning = Clack.warning("Test warning")
      expect(warning).to be_a(Clack::Warning)
      expect(warning.message).to eq("Test warning")
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

  describe ".cancelled?" do
    it "is an alias for cancel?" do
      expect(Clack.cancelled?(Clack::CANCEL)).to be true
      expect(Clack.cancelled?("hello")).to be false
    end
  end

  describe ".handle_cancel" do
    it "returns false and does nothing for non-cancelled values" do
      result = Clack.handle_cancel("hello", output: output)
      expect(result).to be false
      expect(output.string).to be_empty
    end

    it "returns true and shows cancel message for CANCEL" do
      result = Clack.handle_cancel(Clack::CANCEL, output: output)
      expect(result).to be true
      expect(output.string).to include("Cancelled")
    end

    it "accepts custom message" do
      Clack.handle_cancel(Clack::CANCEL, "Aborted", output: output)
      expect(output.string).to include("Aborted")
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

  describe ".spin" do
    it "runs block with spinner and returns result" do
      result = Clack.spin("Working...", output: output) { 42 }
      expect(result).to eq(42)
    end

    it "shows success message on completion" do
      Clack.spin("Working...", success: "Done!", output: output) { true }
      expect(output.string).to include("Done!")
    end

    it "shows error message on exception" do
      expect do
        Clack.spin("Working...", output: output) { raise "Boom" }
      end.to raise_error("Boom")
      expect(output.string).to include("Boom")
    end

    it "uses custom error message" do
      expect do
        Clack.spin("Working...", error: "Failed!", output: output) { raise "Boom" }
      end.to raise_error("Boom")
      expect(output.string).to include("Failed!")
    end

    it "yields spinner to block for message updates" do
      Clack.spin("Step 1...", output: output) do |s|
        s.message "Step 2..."
        sleep 0.05  # Let spinner render
      end
      expect(output.string).to include("Step 2")
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

  describe ".settings" do
    after { Clack::Core::Settings.reset! }

    it "returns current settings" do
      settings = Clack.settings
      expect(settings).to be_a(Hash)
      expect(settings).to have_key(:aliases)
      expect(settings).to have_key(:with_guide)
    end
  end

  describe ".update_settings" do
    after { Clack::Core::Settings.reset! }

    it "updates settings" do
      Clack.update_settings(with_guide: false)
      expect(Clack::Core::Settings.with_guide?).to be false
    end

    it "merges alias customizations" do
      Clack.update_settings(aliases: {"y" => :enter})
      expect(Clack::Core::Settings.action?("y")).to eq(:enter)
    end
  end

  describe ".ci?" do
    it "returns boolean" do
      expect([true, false]).to include(Clack.ci?)
    end
  end

  describe ".windows?" do
    it "returns boolean or nil" do
      expect([true, false, nil]).to include(Clack.windows?)
    end
  end

  describe ".tty?" do
    it "returns false for StringIO" do
      expect(Clack.tty?(output)).to be false
    end

    it "returns true for TTY-like output" do
      tty = double("tty", tty?: true)
      expect(Clack.tty?(tty)).to be true
    end
  end

  describe ".columns" do
    it "returns default for non-TTY" do
      expect(Clack.columns(output)).to eq(80)
    end

    it "accepts custom default" do
      expect(Clack.columns(output, default: 100)).to eq(100)
    end
  end

  describe ".rows" do
    it "returns default for non-TTY" do
      expect(Clack.rows(output)).to eq(24)
    end
  end
end
