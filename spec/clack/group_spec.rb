RSpec.describe Clack::Group do
  let(:output) { StringIO.new }

  describe "#prompt" do
    it "requires a block" do
      group = Clack::Group.new
      expect { group.prompt(:name) }.to raise_error(ArgumentError, /Block required/)
    end

    it "accepts string and symbol names" do
      stub_keys("test", :enter)

      result = Clack.group do |g|
        g.prompt("string_key") { Clack.text(message: "Test?", output: output) }
      end

      expect(result).to have_key(:string_key)
    end
  end

  describe "#run" do
    it "collects results from multiple prompts" do
      stub_keys("Alice", :enter, "30", :enter)

      result = Clack.group do |g|
        g.prompt(:name) { Clack.text(message: "Name?", output: output) }
        g.prompt(:age) { Clack.text(message: "Age?", output: output) }
      end

      expect(result).to eq({name: "Alice", age: "30"})
    end

    it "returns CANCEL when first prompt is cancelled" do
      stub_keys(:escape)

      result = Clack.group do |g|
        g.prompt(:name) { Clack.text(message: "Name?", output: output) }
        g.prompt(:age) { Clack.text(message: "Age?", output: output) }
      end

      expect(Clack.cancel?(result)).to be true
    end

    it "returns CANCEL when middle prompt is cancelled" do
      stub_keys("Alice", :enter, :escape)

      result = Clack.group do |g|
        g.prompt(:name) { Clack.text(message: "Name?", output: output) }
        g.prompt(:age) { Clack.text(message: "Age?", output: output) }
        g.prompt(:email) { Clack.text(message: "Email?", output: output) }
      end

      expect(Clack.cancel?(result)).to be true
    end

    it "passes previous results to subsequent prompts" do
      stub_keys("Alice", :enter, :enter)
      received_results = nil

      Clack.group do |g|
        g.prompt(:name) { Clack.text(message: "Name?", output: output) }
        g.prompt(:greeting) do |results|
          received_results = results
          Clack.confirm(message: "Hello #{results[:name]}?", output: output)
        end
      end

      expect(received_results).to eq({name: "Alice"})
    end

    it "freezes results passed to prompts" do
      stub_keys("test", :enter, :enter)
      was_frozen = nil

      Clack.group do |g|
        g.prompt(:name) { Clack.text(message: "Name?", output: output) }
        g.prompt(:confirm) do |results|
          was_frozen = results.frozen?
          Clack.confirm(message: "Continue?", output: output)
        end
      end

      expect(was_frozen).to be true
    end

    it "works with zero-arity blocks" do
      stub_keys("test", :enter)

      result = Clack.group do |g|
        g.prompt(:name) { Clack.text(message: "Name?", output: output) }
      end

      expect(result[:name]).to eq("test")
    end

    it "works with different prompt types" do
      stub_keys("Alice", :enter, "secret", :enter, :enter, :enter, :space, :enter)

      result = Clack.group do |g|
        g.prompt(:name) { Clack.text(message: "Name?", output: output) }
        g.prompt(:password) { Clack.password(message: "Password?", output: output) }
        g.prompt(:confirm) { Clack.confirm(message: "Continue?", output: output) }
        g.prompt(:framework) { Clack.select(message: "Pick:", options: ["a", "b"], output: output) }
        g.prompt(:features) { Clack.multiselect(message: "Choose:", options: ["x", "y"], output: output) }
      end

      expect(result[:name]).to eq("Alice")
      expect(result[:password]).to eq("secret")
      expect(result[:confirm]).to be true
      expect(result[:framework]).to eq("a")
      expect(result[:features]).to eq(["x"])
    end

    it "handles empty group" do
      result = Clack.group do |g|
        # No prompts defined
      end

      expect(result).to eq({})
    end
  end

  describe "on_cancel callback" do
    it "calls on_cancel with partial results when cancelled" do
      stub_keys("Alice", :enter, :escape)
      cancel_results = nil

      Clack.group(on_cancel: ->(r) { cancel_results = r }) do |g|
        g.prompt(:name) { Clack.text(message: "Name?", output: output) }
        g.prompt(:age) { Clack.text(message: "Age?", output: output) }
      end

      expect(cancel_results[:name]).to eq("Alice")
      expect(cancel_results[:age]).to eq(:cancelled)
    end

    it "does not call on_cancel when not cancelled" do
      stub_keys("Alice", :enter)
      cancel_called = false

      Clack.group(on_cancel: ->(_) { cancel_called = true }) do |g|
        g.prompt(:name) { Clack.text(message: "Name?", output: output) }
      end

      expect(cancel_called).to be false
    end

    it "receives frozen results in on_cancel" do
      stub_keys(:escape)
      was_frozen = nil

      Clack.group(on_cancel: ->(r) { was_frozen = r.frozen? }) do |g|
        g.prompt(:name) { Clack.text(message: "Name?", output: output) }
      end

      expect(was_frozen).to be true
    end
  end

  describe "Clack.group" do
    it "requires a block" do
      expect { Clack.group }.to raise_error(ArgumentError, /Block required/)
    end

    it "returns results hash on success" do
      stub_keys("test", :enter)

      result = Clack.group do |g|
        g.prompt(:name) { Clack.text(message: "Name?", output: output) }
      end

      expect(result).to be_a(Hash)
      expect(result[:name]).to eq("test")
    end

    it "returns CANCEL on cancellation" do
      stub_keys(:ctrl_c)

      result = Clack.group do |g|
        g.prompt(:name) { Clack.text(message: "Name?", output: output) }
      end

      expect(result).to equal(Clack::CANCEL)
    end
  end

  describe "#results" do
    it "tracks partial results during group execution" do
      stub_keys("Alice", :enter, "30", :enter)

      group = Clack::Group.new
      group.prompt(:name) { Clack.text(message: "Name?", output: output) }
      group.prompt(:age) { Clack.text(message: "Age?", output: output) }
      group.run

      expect(group.results).to eq({name: "Alice", age: "30"})
    end
  end
end
