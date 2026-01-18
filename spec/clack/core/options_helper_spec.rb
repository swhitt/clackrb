# frozen_string_literal: true

RSpec.describe Clack::Core::OptionsHelper do
  # Create a test class that includes the helper
  let(:test_class) do
    Class.new do
      include Clack::Core::OptionsHelper

      attr_accessor :options, :cursor, :max_items, :scroll_offset

      def initialize(options: [], max_items: nil)
        @options = options
        @max_items = max_items
        @cursor = 0
        @scroll_offset = 0
      end
    end
  end

  describe "#normalize_options" do
    subject { test_class.new }

    it "raises ArgumentError for nil options" do
      expect { subject.normalize_options(nil) }.to raise_error(ArgumentError, /cannot be empty/)
    end

    it "raises ArgumentError for empty options" do
      expect { subject.normalize_options([]) }.to raise_error(ArgumentError, /cannot be empty/)
    end

    it "converts simple strings to option hashes" do
      result = subject.normalize_options(%w[one two three])

      expect(result).to eq([
        {value: "one", label: "one", hint: nil, disabled: false},
        {value: "two", label: "two", hint: nil, disabled: false},
        {value: "three", label: "three", hint: nil, disabled: false}
      ])
    end

    it "converts symbols to option hashes" do
      result = subject.normalize_options(%i[foo bar])

      expect(result).to eq([
        {value: :foo, label: "foo", hint: nil, disabled: false},
        {value: :bar, label: "bar", hint: nil, disabled: false}
      ])
    end

    it "converts integers to option hashes" do
      result = subject.normalize_options([1, 2, 3])

      expect(result).to eq([
        {value: 1, label: "1", hint: nil, disabled: false},
        {value: 2, label: "2", hint: nil, disabled: false},
        {value: 3, label: "3", hint: nil, disabled: false}
      ])
    end

    it "preserves hash options with all keys" do
      input = [{value: "a", label: "Label A", hint: "Hint", disabled: true}]
      result = subject.normalize_options(input)

      expect(result).to eq([
        {value: "a", label: "Label A", hint: "Hint", disabled: true}
      ])
    end

    it "uses value.to_s as label when label is missing" do
      result = subject.normalize_options([{value: :my_value}])

      expect(result.first[:label]).to eq("my_value")
    end

    it "defaults disabled to false when missing" do
      result = subject.normalize_options([{value: "a", label: "A"}])

      expect(result.first[:disabled]).to eq(false)
    end

    it "handles nil value in hash" do
      result = subject.normalize_options([{value: nil, label: "None"}])

      expect(result.first[:value]).to be_nil
      expect(result.first[:label]).to eq("None")
    end

    it "handles false value in hash" do
      result = subject.normalize_options([{value: false, label: "No"}])

      expect(result.first[:value]).to eq(false)
      expect(result.first[:label]).to eq("No")
    end

    it "handles 0 value in hash" do
      result = subject.normalize_options([{value: 0, label: "Zero"}])

      expect(result.first[:value]).to eq(0)
    end

    it "handles empty string value" do
      result = subject.normalize_options([{value: "", label: "Empty"}])

      expect(result.first[:value]).to eq("")
    end

    it "handles mixed option types" do
      result = subject.normalize_options([
        "simple",
        {value: "hash", label: "Hash Option"},
        :symbol
      ])

      expect(result.length).to eq(3)
      expect(result[0][:value]).to eq("simple")
      expect(result[1][:value]).to eq("hash")
      expect(result[2][:value]).to eq(:symbol)
    end
  end

  describe "#find_next_enabled" do
    it "returns next index when next option is enabled" do
      subject = test_class.new(options: [
        {value: "a", disabled: false},
        {value: "b", disabled: false},
        {value: "c", disabled: false}
      ])

      expect(subject.find_next_enabled(0, 1)).to eq(1)
    end

    it "skips disabled options going forward" do
      subject = test_class.new(options: [
        {value: "a", disabled: false},
        {value: "b", disabled: true},
        {value: "c", disabled: false}
      ])

      expect(subject.find_next_enabled(0, 1)).to eq(2)
    end

    it "skips disabled options going backward" do
      subject = test_class.new(options: [
        {value: "a", disabled: false},
        {value: "b", disabled: true},
        {value: "c", disabled: false}
      ])

      expect(subject.find_next_enabled(2, -1)).to eq(0)
    end

    it "wraps around to beginning when going forward past end" do
      subject = test_class.new(options: [
        {value: "a", disabled: false},
        {value: "b", disabled: false},
        {value: "c", disabled: false}
      ])

      expect(subject.find_next_enabled(2, 1)).to eq(0)
    end

    it "wraps around to end when going backward past beginning" do
      subject = test_class.new(options: [
        {value: "a", disabled: false},
        {value: "b", disabled: false},
        {value: "c", disabled: false}
      ])

      expect(subject.find_next_enabled(0, -1)).to eq(2)
    end

    it "skips multiple disabled options" do
      subject = test_class.new(options: [
        {value: "a", disabled: false},
        {value: "b", disabled: true},
        {value: "c", disabled: true},
        {value: "d", disabled: true},
        {value: "e", disabled: false}
      ])

      expect(subject.find_next_enabled(0, 1)).to eq(4)
    end

    it "returns from position when ALL options are disabled" do
      subject = test_class.new(options: [
        {value: "a", disabled: true},
        {value: "b", disabled: true},
        {value: "c", disabled: true}
      ])

      expect(subject.find_next_enabled(1, 1)).to eq(1)
    end

    it "handles single option that is enabled" do
      subject = test_class.new(options: [
        {value: "a", disabled: false}
      ])

      expect(subject.find_next_enabled(0, 1)).to eq(0)
      expect(subject.find_next_enabled(0, -1)).to eq(0)
    end

    it "handles single option that is disabled" do
      subject = test_class.new(options: [
        {value: "a", disabled: true}
      ])

      expect(subject.find_next_enabled(0, 1)).to eq(0)
    end

    it "finds first enabled when called with from=-1 and delta=1" do
      subject = test_class.new(options: [
        {value: "a", disabled: true},
        {value: "b", disabled: false},
        {value: "c", disabled: false}
      ])

      # This is the pattern used in find_initial_cursor
      expect(subject.find_next_enabled(-1, 1)).to eq(1)
    end

    it "handles wrapping with disabled options at boundaries" do
      subject = test_class.new(options: [
        {value: "a", disabled: true},
        {value: "b", disabled: false},
        {value: "c", disabled: true}
      ])

      # From last position (disabled), going forward should wrap to first enabled
      expect(subject.find_next_enabled(2, 1)).to eq(1)
    end
  end

  describe "#find_initial_cursor" do
    it "returns 0 for empty options" do
      subject = test_class.new(options: [])
      expect(subject.find_initial_cursor(nil)).to eq(0)
    end

    it "returns 0 when first option is enabled and no initial_value" do
      subject = test_class.new(options: [
        {value: "a", disabled: false},
        {value: "b", disabled: false}
      ])

      expect(subject.find_initial_cursor(nil)).to eq(0)
    end

    it "skips to first enabled when first option is disabled" do
      subject = test_class.new(options: [
        {value: "a", disabled: true},
        {value: "b", disabled: false}
      ])

      expect(subject.find_initial_cursor(nil)).to eq(1)
    end

    it "returns index of initial_value when found and enabled" do
      subject = test_class.new(options: [
        {value: "a", disabled: false},
        {value: "b", disabled: false},
        {value: "c", disabled: false}
      ])

      expect(subject.find_initial_cursor("b")).to eq(1)
    end

    it "falls back to first enabled when initial_value is disabled" do
      subject = test_class.new(options: [
        {value: "a", disabled: false},
        {value: "b", disabled: true},
        {value: "c", disabled: false}
      ])

      expect(subject.find_initial_cursor("b")).to eq(0)
    end

    it "falls back to first enabled when initial_value is not found" do
      subject = test_class.new(options: [
        {value: "a", disabled: false},
        {value: "b", disabled: false}
      ])

      expect(subject.find_initial_cursor("not_found")).to eq(0)
    end

    it "handles falsy initial_value (false)" do
      subject = test_class.new(options: [
        {value: true, disabled: false},
        {value: false, disabled: false}
      ])

      expect(subject.find_initial_cursor(false)).to eq(1)
    end

    it "handles falsy initial_value (0)" do
      subject = test_class.new(options: [
        {value: 1, disabled: false},
        {value: 0, disabled: false}
      ])

      expect(subject.find_initial_cursor(0)).to eq(1)
    end
  end

  describe "#move_cursor" do
    it "updates cursor and scroll offset" do
      subject = test_class.new(
        options: [{value: "a", disabled: false}, {value: "b", disabled: false}],
        max_items: nil
      )
      subject.cursor = 0

      subject.move_cursor(1)

      expect(subject.cursor).to eq(1)
    end

    it "skips disabled options" do
      subject = test_class.new(options: [
        {value: "a", disabled: false},
        {value: "b", disabled: true},
        {value: "c", disabled: false}
      ])
      subject.cursor = 0

      subject.move_cursor(1)

      expect(subject.cursor).to eq(2)
    end
  end

  describe "#visible_options" do
    it "returns all options when max_items is nil" do
      options = [{value: "a"}, {value: "b"}, {value: "c"}]
      subject = test_class.new(options: options, max_items: nil)

      expect(subject.visible_options).to eq(options)
    end

    it "returns all options when fewer than max_items" do
      options = [{value: "a"}, {value: "b"}]
      subject = test_class.new(options: options, max_items: 5)

      expect(subject.visible_options).to eq(options)
    end

    it "returns slice based on scroll_offset and max_items" do
      options = (1..10).map { |i| {value: i} }
      subject = test_class.new(options: options, max_items: 3)
      subject.scroll_offset = 2

      result = subject.visible_options
      expect(result.length).to eq(3)
      expect(result.first[:value]).to eq(3)
      expect(result.last[:value]).to eq(5)
    end
  end

  describe "#update_scroll" do
    it "does nothing when max_items is nil" do
      subject = test_class.new(
        options: (1..10).map { |i| {value: i} },
        max_items: nil
      )
      subject.cursor = 5
      subject.scroll_offset = 0

      subject.update_scroll

      expect(subject.scroll_offset).to eq(0)
    end

    it "does nothing when options fit in max_items" do
      subject = test_class.new(
        options: [{value: 1}, {value: 2}],
        max_items: 5
      )
      subject.cursor = 1
      subject.scroll_offset = 0

      subject.update_scroll

      expect(subject.scroll_offset).to eq(0)
    end

    it "scrolls down when cursor goes below visible window" do
      subject = test_class.new(
        options: (1..10).map { |i| {value: i} },
        max_items: 3
      )
      subject.scroll_offset = 0
      subject.cursor = 4 # Beyond visible window (0, 1, 2)

      subject.update_scroll

      expect(subject.scroll_offset).to eq(2) # Scrolls so cursor is at bottom
    end

    it "scrolls up when cursor goes above visible window" do
      subject = test_class.new(
        options: (1..10).map { |i| {value: i} },
        max_items: 3
      )
      subject.scroll_offset = 5
      subject.cursor = 3 # Above visible window (5, 6, 7)

      subject.update_scroll

      expect(subject.scroll_offset).to eq(3)
    end

    it "keeps cursor at bottom of window when scrolling down" do
      subject = test_class.new(
        options: (1..10).map { |i| {value: i} },
        max_items: 3
      )
      subject.scroll_offset = 0
      subject.cursor = 3

      subject.update_scroll

      # Cursor 3 should be at position 2 (bottom) of 3-item window
      # So scroll_offset should be 1 (showing items 1, 2, 3)
      expect(subject.scroll_offset).to eq(1)
    end
  end
end
