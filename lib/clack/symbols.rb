module Clack
  module Symbols
    UNICODE = $stdout.tty? && ENV["TERM"] != "dumb" && !ENV["NO_COLOR"]

    def self.unicode? = UNICODE

    # Step indicators
    S_STEP_ACTIVE = unicode? ? "◆" : "*"
    S_STEP_CANCEL = unicode? ? "■" : "x"
    S_STEP_ERROR = unicode? ? "▲" : "x"
    S_STEP_SUBMIT = unicode? ? "◇" : "o"

    # Radio buttons
    S_RADIO_ACTIVE = unicode? ? "●" : ">"
    S_RADIO_INACTIVE = unicode? ? "○" : " "

    # Checkboxes
    S_CHECKBOX_ACTIVE = unicode? ? "◻" : "[•]"
    S_CHECKBOX_SELECTED = unicode? ? "◼" : "[+]"
    S_CHECKBOX_INACTIVE = unicode? ? "◻" : "[ ]"

    # Password mask
    S_PASSWORD_MASK = unicode? ? "▪" : "*"

    # Bars and connectors
    S_BAR = unicode? ? "│" : "|"
    S_BAR_START = unicode? ? "┌" : "+"
    S_BAR_END = unicode? ? "└" : "+"
    S_BAR_H = unicode? ? "─" : "-"
    S_CORNER_TOP_RIGHT = unicode? ? "╮" : "+"
    S_CORNER_TOP_LEFT = unicode? ? "╭" : "+"
    S_CORNER_BOTTOM_RIGHT = unicode? ? "╯" : "+"
    S_CORNER_BOTTOM_LEFT = unicode? ? "╰" : "+"
    S_CONNECT_LEFT = unicode? ? "├" : "+"

    # Log symbols
    S_INFO = unicode? ? "●" : "*"
    S_SUCCESS = unicode? ? "◆" : "*"
    S_WARN = unicode? ? "▲" : "!"
    S_ERROR = unicode? ? "■" : "x"

    # Spinner frames
    SPINNER_FRAMES = unicode? ? %w[◒ ◐ ◓ ◑] : %w[• o O 0]
    SPINNER_DELAY = unicode? ? 0.08 : 0.12
  end
end
