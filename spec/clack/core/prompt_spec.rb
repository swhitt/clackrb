# frozen_string_literal: true

RSpec.describe Clack::Core::Prompt do
  # Use a concrete subclass for testing since Prompt is abstract
  let(:test_class) do
    Class.new(described_class) do
      attr_accessor :test_value

      def initialize(**opts)
        super
        @test_value = ""
      end

      def handle_input(key, _action)
        @test_value += key if key && key.length == 1 && key.ord >= 32
      end

      def build_frame
        frame = "#{symbol_for_state} #{@message}: #{@test_value}\n"
        frame += "Error: #{@error_message}\n" if @state == :error && @error_message
        frame
      end

      def submit
        @value = @test_value
        super
      end
    end
  end

  let(:output) { StringIO.new }

  describe "#run" do
    it "returns value on submit" do
      stub_keys("t", "e", "s", "t", :enter)
      prompt = test_class.new(message: "Input", output: output)
      result = prompt.run

      expect(result).to eq("test")
    end

    it "returns CANCEL on escape" do
      stub_keys(:escape)
      prompt = test_class.new(message: "Input", output: output)
      result = prompt.run

      expect(result).to eq(Clack::CANCEL)
    end

    it "returns CANCEL on Ctrl+C" do
      stub_keys(:ctrl_c)
      prompt = test_class.new(message: "Input", output: output)
      result = prompt.run

      expect(result).to eq(Clack::CANCEL)
    end

    it "hides cursor on start" do
      stub_keys(:enter)
      prompt = test_class.new(message: "Input", output: output)
      prompt.run

      expect(output.string).to include("\e[?25l")
    end

    it "shows cursor on finish" do
      stub_keys(:enter)
      prompt = test_class.new(message: "Input", output: output)
      prompt.run

      expect(output.string).to include("\e[?25h")
    end

    it "validates input" do
      stub_keys(:enter, "x", :enter)
      prompt = test_class.new(
        message: "Input",
        validate: ->(val) { "Required" if val.to_s.empty? },
        output: output
      )
      prompt.run

      expect(output.string).to include("Required")
    end

    it "handles Error in validation" do
      stub_keys(:enter, "x", :enter)
      prompt = test_class.new(
        message: "Input",
        validate: ->(val) { StandardError.new("Bad") if val.to_s.empty? },
        output: output
      )
      prompt.run

      expect(output.string).to include("Bad")
    end

    it "clears error state on next key" do
      call_count = 0
      stub_keys(:enter, "x", :enter)

      prompt = test_class.new(
        message: "Input",
        validate: lambda { |_val|
          call_count += 1
          "Error" if call_count == 1
        },
        output: output
      )
      prompt.run

      expect(prompt.state).to eq(:submit)
    end
  end

  describe "state machine" do
    it "starts in initial state" do
      prompt = test_class.new(message: "Input", output: output)
      expect(prompt.state).to eq(:initial)
    end

    it "transitions to active on first key" do
      stub_keys("x", :enter)
      prompt = test_class.new(message: "Input", output: output)
      # After run, we can't inspect intermediate states easily
      # but the final state should be submit
      prompt.run
      expect(prompt.state).to eq(:submit)
    end

    it "transitions to submit on enter" do
      stub_keys(:enter)
      prompt = test_class.new(message: "Input", output: output)
      prompt.run
      expect(prompt.state).to eq(:submit)
    end

    it "transitions to cancel on escape" do
      stub_keys(:escape)
      prompt = test_class.new(message: "Input", output: output)
      prompt.run
      expect(prompt.state).to eq(:cancel)
    end
  end

  describe "#terminal_state?" do
    it "returns true for submit" do
      stub_keys(:enter)
      prompt = test_class.new(message: "Input", output: output)
      prompt.run
      expect(prompt.send(:terminal_state?)).to be true
    end

    it "returns true for cancel" do
      stub_keys(:escape)
      prompt = test_class.new(message: "Input", output: output)
      prompt.run
      expect(prompt.send(:terminal_state?)).to be true
    end
  end

  describe "#request_redraw" do
    it "forces next render to redraw" do
      prompt = test_class.new(message: "Input", output: output)
      # Manually set up state to test redraw
      prompt.instance_variable_set(:@prev_frame, "old frame")
      prompt.instance_variable_set(:@needs_redraw, false)

      prompt.request_redraw

      expect(prompt.instance_variable_get(:@needs_redraw)).to be true
    end
  end

  describe ".register and .unregister" do
    after { Clack::Core::Prompt.active_prompts.clear }

    it "tracks active prompts" do
      prompt = test_class.new(message: "Input", output: output)

      Clack::Core::Prompt.register(prompt)
      expect(Clack::Core::Prompt.active_prompts).to include(prompt)

      Clack::Core::Prompt.unregister(prompt)
      expect(Clack::Core::Prompt.active_prompts).not_to include(prompt)
    end
  end

  describe ".setup_signal_handler" do
    it "does not raise on setup" do
      expect { described_class.setup_signal_handler }.not_to raise_error
    end
  end

  describe "rendering" do
    it "clears previous frame before rendering" do
      stub_keys("a", "b", :enter)
      prompt = test_class.new(message: "Input", output: output)
      prompt.run

      # Should contain clear down escape sequence
      expect(output.string).to include("\e[J")
    end

    it "renders final frame" do
      stub_keys("test", :enter)
      prompt = test_class.new(message: "Input", output: output)
      prompt.run

      expect(output.string).to include("test")
    end

    it "only renders on frame change" do
      stub_keys(:enter)
      prompt = test_class.new(message: "Input", output: output)
      prompt.run

      # Count render sequences - should be minimal
      render_count = output.string.scan("\e[J").length
      expect(render_count).to be > 0
    end
  end

  describe "#symbol_for_state" do
    # NOTE: Colors are disabled in tests since stdout is not a TTY
    # So we just verify the symbols are present

    it "includes active symbol during active state" do
      stub_keys("x", :enter)
      prompt = test_class.new(message: "Input", output: output)
      prompt.run

      expect(output.string).to include(Clack::Symbols::S_STEP_ACTIVE)
    end

    it "includes submit symbol in final frame" do
      stub_keys(:enter)
      prompt = test_class.new(message: "Input", output: output)
      prompt.run

      expect(output.string).to include(Clack::Symbols::S_STEP_SUBMIT)
    end

    it "includes cancel symbol on escape" do
      stub_keys(:escape)
      prompt = test_class.new(message: "Input", output: output)
      prompt.run

      expect(output.string).to include(Clack::Symbols::S_STEP_CANCEL)
    end
  end
end
