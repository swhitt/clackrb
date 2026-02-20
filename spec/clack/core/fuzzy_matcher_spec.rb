# frozen_string_literal: true

RSpec.describe Clack::Core::FuzzyMatcher do
  describe ".match?" do
    it "matches empty query to anything" do
      expect(described_class.match?("", "foobar")).to be true
    end

    it "matches exact string" do
      expect(described_class.match?("foobar", "foobar")).to be true
    end

    it "matches prefix" do
      expect(described_class.match?("foo", "foobar")).to be true
    end

    it "matches non-consecutive characters in order" do
      expect(described_class.match?("fb", "foobar")).to be true
    end

    it "is case-insensitive" do
      expect(described_class.match?("FOO", "foobar")).to be true
    end

    it "rejects when characters not found in order" do
      expect(described_class.match?("zz", "foobar")).to be false
    end

    it "rejects when characters are in wrong order" do
      expect(described_class.match?("ba", "abc")).to be false
    end
  end

  describe ".score" do
    it "returns 0 for no match" do
      expect(described_class.score("zz", "foobar")).to eq(0)
    end

    it "returns positive score for match" do
      expect(described_class.score("fb", "foobar")).to be > 0
    end

    it "scores consecutive matches higher" do
      consecutive = described_class.score("foo", "foobar")
      scattered = described_class.score("fbr", "foobar")
      expect(consecutive).to be > scattered
    end

    it "scores start-of-string matches higher" do
      at_start = described_class.score("f", "foobar")
      in_middle = described_class.score("b", "foobar")
      expect(at_start).to be > in_middle
    end

    it "scores word boundary matches higher" do
      # "fb" in "foo_bar" — b is at word boundary
      boundary = described_class.score("fb", "foo_bar")
      no_boundary = described_class.score("fb", "fxxbxx")
      expect(boundary).to be > no_boundary
    end

    it "returns 0 for empty query" do
      expect(described_class.score("", "foobar")).to eq(0)
    end
  end

  describe ".filter" do
    let(:options) do
      [
        {value: "app", label: "Apple", hint: nil, disabled: false},
        {value: "ban", label: "Banana", hint: "tropical", disabled: false},
        {value: "chr", label: "Cherry", hint: nil, disabled: false}
      ]
    end

    it "returns all options for empty query" do
      expect(described_class.filter(options, "")).to eq(options)
    end

    it "filters by label" do
      result = described_class.filter(options, "app")
      expect(result.map { |o| o[:value] }).to eq(["app"])
    end

    it "filters by value" do
      result = described_class.filter(options, "ban")
      expect(result.map { |o| o[:value] }).to eq(["ban"])
    end

    it "filters by hint" do
      result = described_class.filter(options, "trop")
      expect(result.map { |o| o[:value] }).to eq(["ban"])
    end

    it "sorts by relevance score" do
      opts = [
        {value: "xbc", label: "xbcdef", hint: nil, disabled: false},
        {value: "abc", label: "abcdef", hint: nil, disabled: false}
      ]
      result = described_class.filter(opts, "abc")
      # "abcdef" has consecutive match at start, should rank first
      expect(result.first[:value]).to eq("abc")
    end

    it "excludes non-matching options" do
      result = described_class.filter(options, "zz")
      expect(result).to be_empty
    end

    it "handles fuzzy matches" do
      result = described_class.filter(options, "ae")
      # "Apple" matches a...e
      expect(result.map { |o| o[:value] }).to include("app")
    end
  end
end
