# frozen_string_literal: true

RSpec.describe Clack::Core::CiMode do
  after { Clack::Core::Settings.reset! }

  describe ".active?" do
    it "returns false by default" do
      expect(described_class.active?).to be false
    end

    it "returns true when ci_mode is true" do
      Clack.update_settings(ci_mode: true)
      expect(described_class.active?).to be true
    end

    it "returns false when ci_mode is false" do
      Clack.update_settings(ci_mode: false)
      expect(described_class.active?).to be false
    end

    context "when ci_mode is :auto" do
      before { Clack.update_settings(ci_mode: :auto) }

      it "returns true in CI environment" do
        allow(Clack::Environment).to receive(:tty?).and_return(true)
        allow(Clack::Environment).to receive(:ci?).and_return(true)
        expect(described_class.active?).to be true
      end

      it "returns true when stdin is not a TTY" do
        allow(Clack::Environment).to receive(:tty?).with($stdin).and_return(false)
        expect(described_class.active?).to be true
      end

      it "returns false when TTY and not CI" do
        allow(Clack::Environment).to receive(:tty?).with($stdin).and_return(true)
        allow(Clack::Environment).to receive(:ci?).and_return(false)
        expect(described_class.active?).to be false
      end
    end
  end
end

RSpec.describe "CI mode integration" do
  around do |example|
    Clack.update_settings(ci_mode: true)
    example.run
  ensure
    Clack::Core::Settings.reset!
  end

  it "auto-submits text with default value" do
    output = StringIO.new
    result = Clack.text(message: "Name?", default_value: "Alice", output: output)
    expect(result).to eq("Alice")
  end

  it "auto-submits text with initial value" do
    output = StringIO.new
    result = Clack.text(message: "Name?", initial_value: "Bob", output: output)
    expect(result).to eq("Bob")
  end

  it "auto-submits text with empty string when no default" do
    output = StringIO.new
    result = Clack.text(message: "Name?", output: output)
    expect(result).to eq("")
  end

  it "auto-submits confirm with initial value" do
    output = StringIO.new
    result = Clack.confirm(message: "Continue?", initial_value: false, output: output)
    expect(result).to be false
  end

  it "auto-submits confirm with default (true)" do
    output = StringIO.new
    result = Clack.confirm(message: "Continue?", output: output)
    expect(result).to be true
  end

  it "auto-submits select with first option" do
    output = StringIO.new
    result = Clack.select(message: "Pick", options: %w[a b c], output: output)
    expect(result).to eq("a")
  end

  it "auto-submits select with initial value" do
    output = StringIO.new
    result = Clack.select(message: "Pick", options: %w[a b c], initial_value: "b", output: output)
    expect(result).to eq("b")
  end

  it "auto-submits multiselect with initial values" do
    output = StringIO.new
    result = Clack.multiselect(
      message: "Pick",
      options: %w[a b c],
      initial_values: %w[a c],
      output: output
    )
    expect(result).to contain_exactly("a", "c")
  end

  it "applies transforms in CI mode" do
    output = StringIO.new
    result = Clack.text(
      message: "Name?",
      initial_value: "alice",
      transform: :upcase,
      output: output
    )
    expect(result).to eq("ALICE")
  end
end
