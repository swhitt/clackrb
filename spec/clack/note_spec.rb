# frozen_string_literal: true

RSpec.describe Clack::Note do
  let(:output) { StringIO.new }

  describe ".render" do
    it "outputs boxed message" do
      described_class.render("Hello World", output: output)
      result = output.string
      expect(result).to include("Hello World")
      expect(result).to include(Clack::Symbols::S_BAR)
    end

    it "includes title when provided" do
      described_class.render("Content", title: "Title", output: output)
      expect(output.string).to include("Title")
    end

    it "handles multiline content" do
      described_class.render("Line 1\nLine 2\nLine 3", output: output)
      result = output.string
      expect(result).to include("Line 1")
      expect(result).to include("Line 2")
      expect(result).to include("Line 3")
    end

    it "handles empty message" do
      expect { described_class.render("", output: output) }.not_to raise_error
    end
  end
end
