# frozen_string_literal: true

RSpec.describe Clack::Prompts::MultilineText do
  let(:output) { StringIO.new }
  subject { described_class.new(message: "Enter message:", output: output) }

  it_behaves_like "a cancellable prompt"

  describe "#run" do
    context "basic operations" do
      it "accepts input and submits with Ctrl+D" do
        stub_keys("hello", :ctrl_d)
        result = subject.run

        expect(result).to eq("hello")
      end

      it "inserts newline with Enter" do
        stub_keys("line1", :enter, "line2", :ctrl_d)
        result = subject.run

        expect(result).to eq("line1\nline2")
      end

      it "returns empty string when submitting empty" do
        stub_keys(:ctrl_d)
        result = subject.run

        expect(result).to eq("")
      end

      it "shows Ctrl+D hint in prompt" do
        stub_keys(:ctrl_d)
        subject.run

        expect(output.string).to include("Ctrl+D to submit")
      end
    end

    context "cursor navigation within line" do
      it "moves cursor left" do
        stub_keys("abc", :left, "x", :ctrl_d)
        result = subject.run

        expect(result).to eq("abxc")
      end

      it "moves cursor right" do
        stub_keys("abc", :left, :left, :right, "x", :ctrl_d)
        result = subject.run

        expect(result).to eq("abxc")
      end

      it "left at line start does nothing" do
        stub_keys("a", :left, :left, :left, "x", :ctrl_d)
        result = subject.run

        expect(result).to eq("xa")
      end

      it "right at line end does nothing" do
        stub_keys("a", :right, :right, "b", :ctrl_d)
        result = subject.run

        expect(result).to eq("ab")
      end
    end

    context "line navigation" do
      it "moves up between lines" do
        stub_keys("line1", :enter, "line2", :up, "X", :ctrl_d)
        result = subject.run

        expect(result).to eq("line1X\nline2")
      end

      it "moves down between lines" do
        stub_keys("line1", :enter, "line2", :up, :down, "X", :ctrl_d)
        result = subject.run

        expect(result).to eq("line1\nline2X")
      end

      it "up at first line does nothing" do
        stub_keys("abc", :up, :up, "X", :ctrl_d)
        result = subject.run

        expect(result).to eq("abcX")
      end

      it "down at last line does nothing" do
        stub_keys("abc", :down, :down, "X", :ctrl_d)
        result = subject.run

        expect(result).to eq("abcX")
      end

      it "clamps column when moving to shorter line" do
        stub_keys("longer", :enter, "short", :up, "X", :ctrl_d)
        result = subject.run

        # Cursor was at end of "short" (col 5), moves to "longer" (col 5), then X
        expect(result).to eq("longeXr\nshort")
      end

      it "clamps column when moving to shorter line from end" do
        stub_keys("abcdef", :enter, "xy", :up, "Z", :ctrl_d)
        result = subject.run

        # After typing "xy", cursor is at col 2. Move up to "abcdef", col stays at 2
        expect(result).to eq("abZcdef\nxy")
      end
    end

    context "backspace" do
      it "deletes character within line" do
        stub_keys("abc", :backspace, :ctrl_d)
        result = subject.run

        expect(result).to eq("ab")
      end

      it "merges lines when at line start" do
        stub_keys("line1", :enter, "line2", :left, :left, :left, :left, :left, :backspace, :ctrl_d)
        result = subject.run

        expect(result).to eq("line1line2")
      end

      it "does nothing at start of first line" do
        stub_keys(:backspace, "a", :ctrl_d)
        result = subject.run

        expect(result).to eq("a")
      end

      it "positions cursor correctly after merge" do
        stub_keys("ab", :enter, "cd", :left, :left, :backspace, "X", :ctrl_d)
        result = subject.run

        # After merge: "abcd" with cursor at position 2 (after "ab")
        expect(result).to eq("abXcd")
      end

      it "handles multiple merges" do
        stub_keys("a", :enter, "b", :enter, "c", :left, :backspace, :left, :backspace, :ctrl_d)
        result = subject.run

        expect(result).to eq("abc")
      end
    end

    context "initial value" do
      it "pre-populates with initial value" do
        stub_keys(:ctrl_d)
        prompt = described_class.new(
          message: "Message:",
          initial_value: "preset",
          output: output
        )
        result = prompt.run

        expect(result).to eq("preset")
      end

      it "handles initial value with newlines" do
        stub_keys(:ctrl_d)
        prompt = described_class.new(
          message: "Message:",
          initial_value: "line1\nline2\nline3",
          output: output
        )
        result = prompt.run

        expect(result).to eq("line1\nline2\nline3")
      end

      it "positions cursor at end of content" do
        stub_keys("X", :ctrl_d)
        prompt = described_class.new(
          message: "Message:",
          initial_value: "preset",
          output: output
        )
        result = prompt.run

        expect(result).to eq("presetX")
      end

      it "can edit initial value" do
        stub_keys(:backspace, :backspace, "YZ", :ctrl_d)
        prompt = described_class.new(
          message: "Message:",
          initial_value: "abcd",
          output: output
        )
        result = prompt.run

        expect(result).to eq("abYZ")
      end
    end

    context "validation" do
      it "shows error on invalid submit" do
        stub_keys(:ctrl_d, "x", :ctrl_d)
        prompt = described_class.new(
          message: "Message:",
          validate: ->(v) { "Required!" if v.strip.empty? },
          output: output
        )
        result = prompt.run

        expect(result).to eq("x")
        expect(output.string).to include("Required!")
      end

      it "recovers from error after editing" do
        stub_keys(:ctrl_d, "valid", :ctrl_d)
        prompt = described_class.new(
          message: "Message:",
          validate: ->(v) { "Required!" if v.strip.empty? },
          output: output
        )
        result = prompt.run

        expect(result).to eq("valid")
      end
    end

    context "unicode and emoji" do
      it "handles unicode characters" do
        stub_keys("日", "本", :ctrl_d)
        result = subject.run

        expect(result).to eq("日本")
      end

      it "handles emoji" do
        stub_keys("👋", "🎉", :ctrl_d)
        result = subject.run

        expect(result).to eq("👋🎉")
      end

      it "handles unicode with cursor movement" do
        stub_keys("日本", :left, "語", :ctrl_d)
        result = subject.run

        expect(result).to eq("日語本")
      end

      it "handles backspace with unicode" do
        stub_keys("日本語", :backspace, :ctrl_d)
        result = subject.run

        expect(result).to eq("日本")
      end
    end

    context "rendering" do
      it "displays multiple lines" do
        stub_keys("line1", :enter, "line2", :ctrl_d)
        subject.run

        expect(output.string).to include("line1")
        expect(output.string).to include("line2")
      end

      it "renders cancelled value in output" do
        stub_keys("text", :escape)
        subject.run

        expect(output.string).to include("text")
      end

      it "renders submitted value in final output" do
        stub_keys("text", :ctrl_d)
        subject.run

        expect(output.string).to include("text")
      end
    end

    context "edge cases" do
      it "handles empty lines" do
        stub_keys(:enter, :enter, :ctrl_d)
        result = subject.run

        expect(result).to eq("\n\n")
      end

      it "handles inserting at middle of line" do
        stub_keys("ac", :left, "b", :ctrl_d)
        result = subject.run

        expect(result).to eq("abc")
      end

      it "splits line correctly on Enter" do
        stub_keys("abcd", :left, :left, :enter, :ctrl_d)
        result = subject.run

        expect(result).to eq("ab\ncd")
      end

      it "vim j/k keys insert text, don't navigate" do
        stub_keys("j", "k", :ctrl_d)
        result = subject.run

        expect(result).to eq("jk")
      end

      it "vim h/l keys insert text, don't move cursor" do
        stub_keys("h", "l", :ctrl_d)
        result = subject.run

        expect(result).to eq("hl")
      end
    end
  end
end
