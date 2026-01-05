RSpec.describe Clack::Symbols do
  describe "step indicators" do
    it "has step symbols defined" do
      expect(Clack::Symbols::S_STEP_ACTIVE).not_to be_empty
      expect(Clack::Symbols::S_STEP_CANCEL).not_to be_empty
      expect(Clack::Symbols::S_STEP_ERROR).not_to be_empty
      expect(Clack::Symbols::S_STEP_SUBMIT).not_to be_empty
    end
  end

  describe "radio buttons" do
    it "has radio symbols defined" do
      expect(Clack::Symbols::S_RADIO_ACTIVE).not_to be_empty
      expect(Clack::Symbols::S_RADIO_INACTIVE).not_to be_empty
    end
  end

  describe "checkboxes" do
    it "has checkbox symbols defined" do
      expect(Clack::Symbols::S_CHECKBOX_ACTIVE).not_to be_empty
      expect(Clack::Symbols::S_CHECKBOX_SELECTED).not_to be_empty
      expect(Clack::Symbols::S_CHECKBOX_INACTIVE).not_to be_empty
    end
  end

  describe "bars" do
    it "has bar symbols defined" do
      expect(Clack::Symbols::S_BAR).not_to be_empty
      expect(Clack::Symbols::S_BAR_START).not_to be_empty
      expect(Clack::Symbols::S_BAR_END).not_to be_empty
    end
  end

  describe "spinner" do
    it "has spinner frames defined" do
      expect(Clack::Symbols::SPINNER_FRAMES).to be_an(Array)
      expect(Clack::Symbols::SPINNER_FRAMES.length).to eq(4)
    end

    it "has spinner delay defined" do
      expect(Clack::Symbols::SPINNER_DELAY).to be_a(Numeric)
    end
  end
end
