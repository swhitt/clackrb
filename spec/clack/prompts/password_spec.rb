RSpec.describe Clack::Prompts::Password do
  let(:output) { StringIO.new }
  subject { described_class.new(message: "Password:", output: output) }

  it_behaves_like "a cancellable prompt"

  describe "#run" do
    it "masks input with asterisks" do
      stub_keys("s", "e", "c", "r", "e", "t", :enter)
      result = subject.run

      expect(result).to eq("secret")
      expect(output.string).to include("*" * 6)
      expect(output.string).not_to include("secret")
    end

    it "handles backspace" do
      stub_keys("a", "b", "c", :backspace, :enter)
      prompt = described_class.new(message: "Password:", output: output)
      result = prompt.run

      expect(result).to eq("ab")
    end

    it "validates input" do
      stub_keys(:enter, "x", :enter)
      prompt = described_class.new(
        message: "Password:",
        validate: ->(val) { "Required" if val.empty? },
        output: output
      )
      result = prompt.run

      expect(result).to eq("x")
    end

    it "uses custom mask character" do
      stub_keys("a", "b", :enter)
      prompt = described_class.new(
        message: "Password:",
        mask: "\u2022",
        output: output
      )
      prompt.run

      expect(output.string).to include("\u2022")
    end

    it "shows masked output on submit" do
      stub_keys("a", "b", "c", :enter)
      prompt = described_class.new(message: "Password:", output: output)
      prompt.run

      # Final frame should show masked value
      expect(output.string).to include("***")
    end

    it "shows masked output on cancel" do
      stub_keys("a", "b", :escape)
      prompt = described_class.new(message: "Password:", output: output)
      prompt.run

      expect(output.string).to include("**")
    end

    it "ignores arrow keys" do
      stub_keys("a", :left, :right, :up, :down, "b", :enter)
      prompt = described_class.new(message: "Password:", output: output)
      result = prompt.run

      expect(result).to eq("ab")
    end
  end
end
