RSpec.describe Clack::Colors do
  describe "color methods" do
    it "wraps text in ANSI codes when enabled" do
      allow(Clack::Colors).to receive(:enabled?).and_return(true)

      expect(Clack::Colors.red("hello")).to eq("\e[31mhello\e[0m")
      expect(Clack::Colors.green("hello")).to eq("\e[32mhello\e[0m")
      expect(Clack::Colors.yellow("hello")).to eq("\e[33mhello\e[0m")
      expect(Clack::Colors.blue("hello")).to eq("\e[34mhello\e[0m")
      expect(Clack::Colors.cyan("hello")).to eq("\e[36mhello\e[0m")
      expect(Clack::Colors.gray("hello")).to eq("\e[90mhello\e[0m")
    end

    it "returns plain text when disabled" do
      allow(Clack::Colors).to receive(:enabled?).and_return(false)

      expect(Clack::Colors.red("hello")).to eq("hello")
      expect(Clack::Colors.green("hello")).to eq("hello")
    end
  end

  describe "text styles" do
    before { allow(Clack::Colors).to receive(:enabled?).and_return(true) }

    it "applies dim" do
      expect(Clack::Colors.dim("text")).to eq("\e[2mtext\e[0m")
    end

    it "applies bold" do
      expect(Clack::Colors.bold("text")).to eq("\e[1mtext\e[0m")
    end

    it "applies inverse" do
      expect(Clack::Colors.inverse("text")).to eq("\e[7mtext\e[0m")
    end

    it "applies strikethrough" do
      expect(Clack::Colors.strikethrough("text")).to eq("\e[9mtext\e[0m")
    end
  end
end
