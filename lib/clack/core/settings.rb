module Clack
  module Core
    module Settings
      ACTIONS = %i[up down left right space enter cancel].freeze

      ALIASES = {
        "k" => :up,
        "j" => :down,
        "h" => :left,
        "l" => :right,
        "\e[A" => :up,
        "\e[B" => :down,
        "\e[C" => :right,
        "\e[D" => :left,
        "\r" => :enter,
        "\n" => :enter,
        " " => :space,
        "\e" => :cancel,
        "\u0003" => :cancel  # Ctrl+C
      }.freeze

      MESSAGES = {
        cancel: "Cancelled",
        error: "Something went wrong"
      }.freeze

      class << self
        def action?(key)
          ALIASES[key] if ACTIONS.include?(ALIASES[key])
        end

        def cancel?(key)
          ALIASES[key] == :cancel
        end

        def enter?(key)
          ALIASES[key] == :enter
        end
      end
    end
  end
end
