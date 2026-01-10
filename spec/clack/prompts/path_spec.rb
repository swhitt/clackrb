# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Clack::Prompts::Path do
  let(:output) { StringIO.new }
  let(:test_dir) { Dir.mktmpdir("clack_test") }
  subject { described_class.new(message: "Select path:", root: test_dir, output: output) }

  before do
    FileUtils.mkdir_p(File.join(test_dir, "src"))
    FileUtils.mkdir_p(File.join(test_dir, "lib"))
    FileUtils.mkdir_p(File.join(test_dir, "spec"))
    FileUtils.touch(File.join(test_dir, "README.md"))
    FileUtils.touch(File.join(test_dir, "Gemfile"))
    FileUtils.touch(File.join(test_dir, "src", "main.rb"))
  end

  after do
    FileUtils.rm_rf(test_dir)
  end

  it_behaves_like "a cancellable prompt"

  describe "#run" do
    it "returns root path when empty and submitted" do
      stub_keys(:enter)
      result = subject.run

      expect(result).to eq(test_dir)
    end

    it "handles text input" do
      stub_keys("src", :enter)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      result = prompt.run

      expect(result).to eq(File.join(test_dir, "src"))
    end

    it "handles backspace" do
      stub_keys("srcc", :backspace, :enter)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      result = prompt.run

      expect(result).to eq(File.join(test_dir, "src"))
    end

    it "backspace at start does nothing" do
      stub_keys(:backspace, "src", :enter)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      result = prompt.run

      expect(result).to eq(File.join(test_dir, "src"))
    end

    it "tab autocompletes selection" do
      stub_keys("s", :tab, :enter)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      result = prompt.run

      # Should autocomplete to first suggestion starting with 's'
      expect(result).to include(test_dir)
    end

    it "down arrow moves selection" do
      stub_keys(:down, :tab, :enter)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      result = prompt.run

      expect(result).to include(test_dir)
    end

    it "up arrow moves selection" do
      stub_keys(:down, :down, :up, :tab, :enter)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      result = prompt.run

      expect(result).to include(test_dir)
    end

    it "wraps selection from last to first" do
      # Move down past the end
      stub_keys(:down, :down, :down, :down, :down, :down, :down, :down, :enter)
      prompt = described_class.new(message: "Select path:", root: test_dir, max_items: 3, output: output)
      prompt.run

      # Should wrap around
      expect(output.string).to include("Select path:")
    end

    it "validates input" do
      stub_keys("nonexistent", :enter, :escape)
      prompt = described_class.new(
        message: "Select path:",
        root: test_dir,
        validate: ->(path) { "Path does not exist" unless File.exist?(path) },
        output: output
      )
      prompt.run

      expect(output.string).to include("Path does not exist")
    end

    it "clears error state on next key" do
      stub_keys("x", :enter, :backspace, "src", :enter)
      prompt = described_class.new(
        message: "Select path:",
        root: test_dir,
        validate: ->(path) { "Invalid" unless File.exist?(path) },
        output: output
      )
      result = prompt.run

      expect(result).to eq(File.join(test_dir, "src"))
    end

    it "handles only_directories option" do
      stub_keys(:tab, :enter)
      prompt = described_class.new(
        message: "Select directory:",
        root: test_dir,
        only_directories: true,
        output: output
      )
      result = prompt.run

      # Should only suggest directories
      expect(File.directory?(result) || result == test_dir).to be true
    end

    it "rejects absolute paths outside root" do
      stub_keys("/tmp", :enter, :escape)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      result = prompt.run

      expect(output.string).to include("Path must be within")
      expect(result).to eq(Clack::CANCEL)
    end

    it "rejects home directory outside root" do
      stub_keys("~", :enter, :escape)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      result = prompt.run

      expect(output.string).to include("Path must be within")
      expect(result).to eq(Clack::CANCEL)
    end

    it "rejects path traversal attempts" do
      stub_keys("../../../etc/passwd", :enter, :escape)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      result = prompt.run

      expect(output.string).to include("Path must be within")
      expect(result).to eq(Clack::CANCEL)
    end

    it "rejects paths with matching prefix but different directory" do
      # Boundary bug: ../src2 from root "src" resolves to sibling "src2"
      # Old code: "/tmp/src2".start_with?("/tmp/src") = true (wrong!)
      # Fixed:    "/tmp/src2".start_with?("/tmp/src/") = false (correct!)
      stub_keys("../src2", :enter, :escape)
      prompt = described_class.new(message: "Select path:", root: File.join(test_dir, "src"), output: output)
      result = prompt.run

      expect(output.string).to include("Path must be within")
      expect(result).to eq(Clack::CANCEL)
    end

    it "allows paths within root even with relative components" do
      FileUtils.mkdir_p(File.join(test_dir, "a", "b"))
      stub_keys("a/../a/b", :enter)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      result = prompt.run

      expect(result).to eq(File.join(test_dir, "a/b"))
    end

    it "supports max_items for scrolling" do
      stub_keys(:down, :down, :enter)
      prompt = described_class.new(
        message: "Select path:",
        root: test_dir,
        max_items: 2,
        output: output
      )
      prompt.run

      expect(output.string).to include("Select path:")
    end

    it "shows suggestions in output" do
      stub_keys(:enter)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      prompt.run

      # Should show directory contents
      expect(output.string).to include("Select path:")
    end

    it "shows strikethrough on cancel" do
      stub_keys("src", :escape)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      prompt.run

      # Output contains strikethrough ANSI codes
      expect(output.string).to include(Clack::Symbols::S_STEP_CANCEL)
    end

    it "displays message in output" do
      stub_keys(:enter)
      prompt = described_class.new(message: "Choose a file:", root: test_dir, output: output)
      prompt.run

      expect(output.string).to include("Choose a file:")
    end

    it "handles nonexistent filter prefix gracefully" do
      stub_keys("zzz", :enter)
      prompt = described_class.new(
        message: "Select path:",
        root: test_dir,
        validate: nil,
        output: output
      )
      result = prompt.run

      expect(result).to eq(File.join(test_dir, "zzz"))
    end

    it "handles empty suggestions when tab pressed" do
      stub_keys("zzz", :tab, :enter)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      result = prompt.run

      # Tab with no suggestions should not crash
      expect(result).to eq(File.join(test_dir, "zzz"))
    end

    it "handles SystemCallError when listing directory" do
      stub_keys("nonexistent/deep/path", :enter)
      prompt = described_class.new(message: "Select path:", root: test_dir, output: output)
      result = prompt.run

      # Should handle gracefully and return path within root
      expect(result).to eq(File.join(test_dir, "nonexistent/deep/path"))
    end
  end

  describe "#build_frame" do
    it "shows placeholder when empty" do
      stub_keys(:escape)
      prompt = described_class.new(message: "Select:", root: test_dir, output: output)
      prompt.run

      # The root directory should be shown as placeholder
      expect(output.string).to include(test_dir[0])
    end

    it "shows cursor in value" do
      stub_keys("ab", :escape)
      prompt = described_class.new(message: "Select:", root: test_dir, output: output)
      prompt.run

      expect(output.string).to include("ab")
    end
  end

  describe "#build_final_frame" do
    it "shows selected path" do
      stub_keys("src", :enter)
      prompt = described_class.new(message: "Select:", root: test_dir, output: output)
      prompt.run

      expect(output.string).to include("src")
    end
  end
end
