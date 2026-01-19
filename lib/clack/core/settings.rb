# frozen_string_literal: true

module Clack
  module Core
    module Settings
      # Navigation and control actions
      ACTIONS = %i[up down left right space enter cancel].freeze

      # Key code constants
      KEY_BACKSPACE = "\b"        # ASCII 8: Backspace
      KEY_DELETE = "\u007F"       # ASCII 127: Delete (often sent by backspace key)
      KEY_CTRL_C = "\u0003"       # ASCII 3: Ctrl+C (interrupt)
      KEY_CTRL_D = "\u0004"       # ASCII 4: Ctrl+D (EOF, used for multiline submit)
      KEY_ESCAPE = "\e"           # ASCII 27: Escape
      KEY_ENTER = "\r"            # ASCII 13: Carriage return
      KEY_NEWLINE = "\n"          # ASCII 10: Line feed
      KEY_SPACE = " "             # ASCII 32: Space

      # First printable ASCII character (space)
      PRINTABLE_CHAR_MIN = 32

      # Key to action mappings
      ALIASES = {
        "k" => :up,
        "j" => :down,
        "h" => :left,
        "l" => :right,
        "\e[A" => :up,
        "\e[B" => :down,
        "\e[C" => :right,
        "\e[D" => :left,
        KEY_ENTER => :enter,
        KEY_NEWLINE => :enter,
        KEY_SPACE => :space,
        KEY_ESCAPE => :cancel,
        KEY_CTRL_C => :cancel
      }.freeze

      # Global configuration (mutable)
      @config = {
        aliases: ALIASES.dup,
        with_guide: true
      }
      @config_mutex = Mutex.new

      class << self
        # Get a copy of the current global config
        # @return [Hash] Current configuration
        def config
          @config_mutex.synchronize { @config.dup }
        end

        # Update global settings
        # @param aliases [Hash, nil] Custom key to action mappings (merged with defaults)
        # @param with_guide [Boolean, nil] Whether to show guide bars
        # @return [Hash] Updated configuration
        def update(aliases: nil, with_guide: nil)
          @config_mutex.synchronize do
            @config[:aliases] = ALIASES.merge(aliases) if aliases
            @config[:with_guide] = with_guide unless with_guide.nil?
            @config.dup
          end
        end

        # Reset settings to defaults
        def reset!
          @config_mutex.synchronize do
            @config = {
              aliases: ALIASES.dup,
              with_guide: true
            }
          end
        end

        # Check if guide bars should be shown
        # @return [Boolean]
        def with_guide?
          @config_mutex.synchronize { @config[:with_guide] }
        end

        def action?(key)
          aliases = @config_mutex.synchronize { @config[:aliases] }
          aliases[key] if ACTIONS.include?(aliases[key])
        end

        # Check if a key is a printable character
        def printable?(key)
          key && key.length == 1 && key.ord >= PRINTABLE_CHAR_MIN
        end

        # Check if a key is a backspace/delete
        def backspace?(key)
          [KEY_BACKSPACE, KEY_DELETE].include?(key)
        end
      end
    end
  end
end
