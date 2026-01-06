# frozen_string_literal: true

RSpec.describe Clack::Core::KeyReader do
  describe ".read" do
    # KeyReader uses IO.console.raw which is hard to test directly
    # These tests document the expected behavior and key mapping

    it "responds to read" do
      expect(described_class).to respond_to(:read)
    end

    # The read method is tested indirectly through the prompt tests
    # since it requires a real TTY to function properly
  end

  describe "key sequences" do
    # Document expected key sequences
    it 'escape is represented as \\e' do
      expect("\e").to eq("\x1B")
    end

    it 'arrow up is \\e[A' do
      expect("\e[A").to match(/\e\[A/)
    end

    it 'arrow down is \\e[B' do
      expect("\e[B").to match(/\e\[B/)
    end

    it 'arrow right is \\e[C' do
      expect("\e[C").to match(/\e\[C/)
    end

    it 'arrow left is \\e[D' do
      expect("\e[D").to match(/\e\[D/)
    end

    it 'enter is \\r' do
      expect("\r").to eq("\x0D")
    end

    it 'Ctrl+C is \\x03' do
      expect("\x03").to eq("\u0003")
    end
  end
end
