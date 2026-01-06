# frozen_string_literal: true

RSpec.describe Clack::Stream do
  let(:output) { StringIO.new }

  describe ".info" do
    it "outputs with info symbol on first line" do
      described_class.info(["Line 1", "Line 2"], output: output)

      expect(output.string).to include(Clack::Symbols::S_INFO)
    end

    it "outputs bar on subsequent lines" do
      described_class.info(["Line 1", "Line 2"], output: output)

      expect(output.string).to include(Clack::Symbols::S_BAR)
    end

    it "handles single line" do
      described_class.info(["Only one"], output: output)

      expect(output.string).to include("Only one")
    end

    it "yields each line when block given" do
      lines = []
      described_class.info(%w[a b]) { |line| lines << line }

      expect(lines).to eq(%w[a b])
    end
  end

  describe ".success" do
    it "outputs with success symbol" do
      described_class.success(["Done"], output: output)

      expect(output.string).to include(Clack::Symbols::S_SUCCESS)
    end
  end

  describe ".step" do
    it "outputs with step symbol" do
      described_class.step(["Step 1"], output: output)

      expect(output.string).to include(Clack::Symbols::S_STEP_SUBMIT)
    end
  end

  describe ".warn" do
    it "outputs with warning symbol" do
      described_class.warn(["Warning!"], output: output)

      expect(output.string).to include(Clack::Symbols::S_WARN)
    end
  end

  describe ".error" do
    it "outputs with error symbol" do
      described_class.error(["Error!"], output: output)

      expect(output.string).to include(Clack::Symbols::S_ERROR)
    end
  end

  describe ".message" do
    it "outputs with bar symbol" do
      described_class.message(["Hello"], output: output)

      expect(output.string).to include(Clack::Symbols::S_BAR)
      expect(output.string).to include("Hello")
    end

    it "handles multiline messages" do
      described_class.message(["Line 1", "Line 2"], output: output)

      expect(output.string).to include("Line 1")
      expect(output.string).to include("Line 2")
    end
  end

  describe "source types" do
    it "handles array source" do
      described_class.info(%w[a b c], output: output)

      expect(output.string).to include("a")
      expect(output.string).to include("b")
      expect(output.string).to include("c")
    end

    it "handles StringIO source" do
      source = StringIO.new("line1\nline2\n")
      described_class.info(source, output: output)

      expect(output.string).to include("line1")
      expect(output.string).to include("line2")
    end

    it "handles String source" do
      described_class.info("line1\nline2\n", output: output)

      expect(output.string).to include("line1")
      expect(output.string).to include("line2")
    end

    it "handles enumerable source" do
      described_class.info(1..3, output: output)

      expect(output.string).to include("1")
      expect(output.string).to include("2")
      expect(output.string).to include("3")
    end
  end

  describe ".command" do
    it "streams output from shell command" do
      result = described_class.command("echo hello", output: output)

      expect(output.string).to include("hello")
      expect(result).to be true
    end

    it "returns false for failed command" do
      result = described_class.command("false", output: output)

      expect(result).to be false
    end

    it "uses specified type" do
      described_class.command("echo test", type: :success, output: output)

      expect(output.string).to include(Clack::Symbols::S_SUCCESS)
    end

    it "captures stderr" do
      # Use bash -c to ensure stderr redirection works
      described_class.command("bash -c 'echo error >&2'", type: :error, output: output)

      expect(output.string).to include("error")
    end
  end
end
