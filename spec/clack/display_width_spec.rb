# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Clack::Utils display width" do
  describe ".display_width" do
    it "returns 0 for empty string" do
      expect(Clack::Utils.display_width("")).to eq(0)
    end

    it "returns character count for ASCII strings" do
      expect(Clack::Utils.display_width("hello")).to eq(5)
      expect(Clack::Utils.display_width("abc 123")).to eq(7)
    end

    it "returns 2 per CJK ideograph" do
      expect(Clack::Utils.display_width("中文")).to eq(4)
      expect(Clack::Utils.display_width("漢字")).to eq(4)
    end

    it "returns 2 for emoji" do
      expect(Clack::Utils.display_width("🚀")).to eq(2)
      expect(Clack::Utils.display_width("😀✅")).to eq(4)
    end

    it "returns 1 for combining character sequences" do
      # e + combining acute accent = single grapheme, width 1
      expect(Clack::Utils.display_width("é")).to eq(1)
      # a + combining tilde
      expect(Clack::Utils.display_width("ã")).to eq(1)
    end

    it "returns 0 for zero-width characters alone" do
      expect(Clack::Utils.display_width("​")).to eq(0) # zero-width space
      expect(Clack::Utils.display_width("﻿")).to eq(0) # BOM / zero-width no-break space
    end

    it "handles mixed ASCII and CJK" do
      expect(Clack::Utils.display_width("Hi 世界!")).to eq(8) # H(1) i(1) (1) 世(2) 界(2) !(1)
    end

    it "handles fullwidth forms as width 2" do
      expect(Clack::Utils.display_width("ＡＢＣ")).to eq(6)
    end

    it "handles Hangul syllables as width 2" do
      expect(Clack::Utils.display_width("한글")).to eq(4)
    end

    it "handles ZWJ emoji sequences as width 2" do
      # Family emoji (ZWJ sequence) renders as a single wide glyph
      expect(Clack::Utils.display_width("👨‍👩‍👧‍👦")).to eq(2)
    end

    it "handles flag emoji as width 2" do
      expect(Clack::Utils.display_width("🇺🇸")).to eq(2)
    end
  end

  describe ".visible_length" do
    it "strips ANSI and measures display width for CJK" do
      colored = "\e[32m中文\e[0m"
      expect(Clack::Utils.visible_length(colored)).to eq(4)
    end

    it "strips ANSI and measures display width for emoji" do
      colored = "\e[1m🚀\e[0m"
      expect(Clack::Utils.visible_length(colored)).to eq(2)
    end

    it "strips ANSI and returns correct width for ASCII" do
      colored = "\e[31mhello\e[0m"
      expect(Clack::Utils.visible_length(colored)).to eq(5)
    end

    it "returns 0 for empty string" do
      expect(Clack::Utils.visible_length("")).to eq(0)
    end

    it "handles mixed ANSI + CJK + ASCII" do
      text = "\e[32mHi\e[0m 世界"
      expect(Clack::Utils.visible_length(text)).to eq(7) # H(1) i(1) (1) 世(2) 界(2)
    end
  end
end
