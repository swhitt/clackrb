# frozen_string_literal: true

RSpec.describe Clack::Box do
  let(:output) { StringIO.new }

  describe ".render" do
    it "renders a basic box" do
      described_class.render("Hello", output: output)
      expect(output.string).to include("Hello")
      expect(output.string).to include(Clack::Symbols::S_BAR)
    end

    it "renders with title" do
      described_class.render("Content", title: "Title", output: output)
      expect(output.string).to include("Title")
      expect(output.string).to include("Content")
    end

    it "uses rounded corners by default" do
      described_class.render("Hi", output: output)
      expect(output.string).to include(Clack::Symbols::S_CORNER_TOP_LEFT)
      expect(output.string).to include(Clack::Symbols::S_CORNER_BOTTOM_RIGHT)
    end

    it "uses square corners when rounded: false" do
      described_class.render("Hi", rounded: false, output: output)
      expect(output.string).to include(Clack::Symbols::S_BAR_START)
      expect(output.string).to include(Clack::Symbols::S_BAR_END_RIGHT)
    end

    it "handles multi-line content" do
      described_class.render("Line 1\nLine 2", output: output)
      expect(output.string).to include("Line 1")
      expect(output.string).to include("Line 2")
    end

    it "handles fixed width" do
      described_class.render("Hi", width: 20, output: output)
      lines = output.string.lines
      expect(lines.first.strip.length).to be >= 20
    end

    it "centers content when content_align: :center" do
      described_class.render("Hi", width: 20, content_align: :center, output: output)
      # Content line should have padding on both sides
      content_line = output.string.lines.find { |l| l.include?("Hi") }
      expect(content_line).to match(/\s{2,}Hi\s{2,}/)
    end

    it "aligns content right when content_align: :right" do
      described_class.render("Hi", width: 20, content_align: :right, output: output)
      content_line = output.string.lines.find { |l| l.include?("Hi") }
      # Right-aligned content should have more space on left
      expect(content_line).to match(/\s{5,}Hi/)
    end

    it "truncates long titles" do
      long_title = "A" * 100
      described_class.render("Hi", title: long_title, width: 20, output: output)
      expect(output.string).to include("...")
    end

    it "applies custom border formatting" do
      custom_format = ->(text) { "[#{text}]" }
      described_class.render("Hi", format_border: custom_format, output: output)
      expect(output.string).to include("[")
    end
  end
end
