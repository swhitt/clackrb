# frozen_string_literal: true

require "io/console"

module Clack
  # Environment detection utilities for cross-platform compatibility
  # and CI/terminal environment awareness.
  module Environment
    # Default Escape-sequence detection timeout, in seconds.
    DEFAULT_ESCAPE_TIMEOUT = 0.05

    class << self
      # Check if running on Windows
      # @return [Boolean]
      def windows?
        return @windows if defined?(@windows)

        @windows = !!(RUBY_PLATFORM =~ /mswin|mingw|cygwin|bccwin/i)
      end

      # Check if running in a CI environment
      # Common CI env vars: CI, CONTINUOUS_INTEGRATION, BUILD_NUMBER, GITHUB_ACTIONS, etc.
      # @return [Boolean]
      def ci?
        return @ci if defined?(@ci)

        @ci = ENV["CI"] == "true" ||
          ENV["CONTINUOUS_INTEGRATION"] == "true" ||
          ENV.key?("BUILD_NUMBER") ||
          ENV.key?("GITHUB_ACTIONS") ||
          ENV.key?("GITLAB_CI") ||
          ENV.key?("CIRCLECI") ||
          ENV.key?("TRAVIS") ||
          ENV.key?("JENKINS_URL") ||
          ENV.key?("TEAMCITY_VERSION") ||
          ENV.key?("BUILDKITE")
      end

      # Check if stdout is a TTY (interactive terminal)
      # @param output [IO] Output stream to check (default: $stdout)
      # @return [Boolean]
      def tty?(output = $stdout)
        output.respond_to?(:tty?) && output.tty?
      rescue IOError
        false
      end

      # Check if running in Windows Terminal (modern)
      # @return [Boolean]
      def windows_terminal?
        windows? && ENV.key?("WT_SESSION")
      end

      # Check if running in a dumb terminal (no ANSI support)
      # @return [Boolean]
      def dumb_terminal?
        ENV["TERM"] == "dumb"
      end

      # Check if ANSI colors are supported
      # @param output [IO] Output stream to check
      # @return [Boolean]
      def colors_supported?(output = $stdout)
        return false if ENV["NO_COLOR"]
        return true if ENV["FORCE_COLOR"]
        return false unless tty?(output)
        return false if dumb_terminal?

        # Windows: Modern Windows Terminal, ConEmu, ANSICON, or Windows 10 1511+
        # all support ANSI. We optimistically assume modern systems support it.
        true
      end

      # Get terminal columns (width)
      # @param output [IO] Output stream (default: $stdout)
      # @param default [Integer] Default if detection fails
      # @return [Integer]
      def columns(output = $stdout, default: 80)
        return default unless tty?(output)

        if output.respond_to?(:winsize)
          _, cols = output.winsize
          (cols > 0) ? cols : default
        else
          default
        end
      rescue IOError, SystemCallError
        default
      end

      # Get terminal rows (height)
      # @param output [IO] Output stream (default: $stdout)
      # @param default [Integer] Default if detection fails
      # @return [Integer]
      def rows(output = $stdout, default: 24)
        return default unless tty?(output)

        if output.respond_to?(:winsize)
          rows, = output.winsize
          (rows > 0) ? rows : default
        else
          default
        end
      rescue IOError, SystemCallError
        default
      end

      # Get terminal dimensions as [rows, columns]
      # @param output [IO] Output stream
      # @return [Array<Integer>] [rows, columns]
      def dimensions(output = $stdout)
        [rows(output), columns(output)]
      end

      # Check if raw mode is supported for input
      # @param input [IO] Input stream (default: $stdin)
      # @return [Boolean]
      def raw_mode_supported?(input = $stdin)
        return false unless input.respond_to?(:raw)

        # On Windows without proper console, raw mode may fail
        if windows? && !windows_terminal?
          begin
            IO.console&.respond_to?(:raw)
          rescue IOError, SystemCallError
            false
          end
        else
          true
        end
      end

      # Escape-sequence detection timeout, in seconds.
      #
      # After an Escape byte arrives, the key reader waits this long for a
      # follow-up byte to decide whether it's a standalone Escape or the start
      # of an arrow-key / CSI sequence. The 50ms default is fine locally but too
      # tight over high-latency links (slow SSH, mosh), where the follow-up
      # bytes lag and arrow keys get misread as a bare Escape (cancelling the
      # prompt). Override with the +CLACK_ESCAPE_TIMEOUT+ env var, in
      # milliseconds, e.g. +CLACK_ESCAPE_TIMEOUT=250+ for a slow connection.
      #
      # Invalid or non-positive values fall back to the default.
      #
      # @return [Float] timeout in seconds
      def escape_timeout
        raw = ENV["CLACK_ESCAPE_TIMEOUT"]
        return DEFAULT_ESCAPE_TIMEOUT unless raw

        ms = Float(raw, exception: false)
        return DEFAULT_ESCAPE_TIMEOUT unless ms&.positive?

        ms / 1000.0
      end

      # Reset cached environment checks (useful for testing)
      def reset!
        remove_instance_variable(:@windows) if defined?(@windows)
        remove_instance_variable(:@ci) if defined?(@ci)
      end
    end
  end
end
