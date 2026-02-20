# frozen_string_literal: true

module Clack
  # Unicode and ASCII symbols used for prompt rendering.
  # Automatically selects Unicode or ASCII fallback based on terminal capabilities.
  module Symbols
    class << self
      # Check if unicode output is enabled.
      # CLACK_UNICODE=1 forces unicode, CLACK_UNICODE=0 forces ASCII.
      # Otherwise auto-detects from TTY and TERM.
      def unicode?
        return @unicode if defined?(@unicode)

        @unicode = compute_unicode_support
      end

      # Reset cached unicode detection (useful for testing).
      # @return [void]
      def reset!
        remove_instance_variable(:@unicode) if defined?(@unicode)
      end

      private

      def compute_unicode_support
        # Explicit override
        return ENV["CLACK_UNICODE"] == "1" if ENV["CLACK_UNICODE"]

        # Default: TTY and not dumb terminal
        $stdout.tty? && ENV["TERM"] != "dumb" && !ENV["NO_COLOR"]
      end
    end

    # Step indicators
    S_STEP_ACTIVE = unicode? ? "◆" : "*"
    # Unicode cancel step indicator, or ASCII fallback.
    S_STEP_CANCEL = unicode? ? "■" : "x"
    # Unicode error step indicator, or ASCII fallback.
    S_STEP_ERROR = unicode? ? "▲" : "x"
    # Unicode submit step indicator, or ASCII fallback.
    S_STEP_SUBMIT = unicode? ? "◇" : "o"

    # Radio buttons
    S_RADIO_ACTIVE = unicode? ? "●" : ">"
    # Unicode inactive radio button, or ASCII fallback.
    S_RADIO_INACTIVE = unicode? ? "○" : " "

    # Checkboxes
    S_CHECKBOX_ACTIVE = unicode? ? "◻" : "[•]"
    # Unicode selected checkbox, or ASCII fallback.
    S_CHECKBOX_SELECTED = unicode? ? "◼" : "[+]"
    # Unicode inactive checkbox, or ASCII fallback.
    S_CHECKBOX_INACTIVE = unicode? ? "◻" : "[ ]"

    # Password mask
    S_PASSWORD_MASK = unicode? ? "▪" : "*"

    # Bars and connectors
    S_BAR = unicode? ? "│" : "|"
    # Unicode bar start connector, or ASCII fallback.
    S_BAR_START = unicode? ? "┌" : "+"
    # Unicode bar end connector, or ASCII fallback.
    S_BAR_END = unicode? ? "└" : "+"
    # Unicode horizontal bar, or ASCII fallback.
    S_BAR_H = unicode? ? "─" : "-"
    # Unicode top-right corner, or ASCII fallback.
    S_CORNER_TOP_RIGHT = unicode? ? "╮" : "+"
    # Unicode top-left corner, or ASCII fallback.
    S_CORNER_TOP_LEFT = unicode? ? "╭" : "+"
    # Unicode bottom-right corner, or ASCII fallback.
    S_CORNER_BOTTOM_RIGHT = unicode? ? "╯" : "+"
    # Unicode bottom-left corner, or ASCII fallback.
    S_CORNER_BOTTOM_LEFT = unicode? ? "╰" : "+"
    # Unicode left T-connector, or ASCII fallback.
    S_CONNECT_LEFT = unicode? ? "├" : "+"

    # Square corners (for box with rounded: false)
    S_BAR_START_RIGHT = unicode? ? "┐" : "+"
    # Unicode square bottom-right corner, or ASCII fallback.
    S_BAR_END_RIGHT = unicode? ? "┘" : "+"

    # Log symbols
    S_INFO = unicode? ? "●" : "*"
    # Unicode success log symbol, or ASCII fallback.
    S_SUCCESS = unicode? ? "◆" : "*"
    # Unicode warning log symbol, or ASCII fallback.
    S_WARN = unicode? ? "▲" : "!"
    # Unicode error log symbol, or ASCII fallback.
    S_ERROR = unicode? ? "■" : "x"

    # File system
    S_FOLDER = unicode? ? "📁" : "[D]"
    # Unicode file icon, or ASCII fallback.
    S_FILE = unicode? ? "📄" : "[F]"

    # Spinner frames - quarter circle rotation pattern
    SPINNER_FRAMES = unicode? ? %w[◒ ◐ ◓ ◑] : %w[• o O 0]
    # Delay between spinner frame updates (seconds).
    SPINNER_DELAY = unicode? ? 0.08 : 0.12

    # Progress bar characters
    S_PROGRESS_FILLED = unicode? ? "█" : "#"
    # Unicode empty progress segment, or ASCII fallback.
    S_PROGRESS_EMPTY = unicode? ? "░" : "-"

    # Alternative progress bar (smoother gradient)
    S_PROGRESS_BLOCKS = unicode? ? %w[░ ▒ ▓ █] : %w[- = # #]
  end
end
