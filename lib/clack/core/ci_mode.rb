# frozen_string_literal: true

module Clack
  module Core
    # Non-interactive mode for CI environments and piped input.
    #
    # When enabled, prompts auto-submit with their default values instead
    # of waiting for user input. Useful for CI pipelines, automated testing,
    # and scripted usage where stdin isn't a TTY.
    #
    # Enable explicitly:
    #   Clack.update_settings(ci_mode: true)
    #
    # Or auto-detect (non-TTY stdin or CI environment variable):
    #   Clack.update_settings(ci_mode: :auto)
    module CiMode
      class << self
        # Check if CI mode is currently active.
        #
        # @return [Boolean]
        def active?
          setting = Settings.config[:ci_mode]
          case setting
          when true
            true
          when :auto
            !Environment.tty?($stdin) || Environment.ci?
          else
            false
          end
        end
      end
    end
  end
end
