# frozen_string_literal: true

require "English"
require "stringio"

module Clack
  # Stream logging utility for iterables, enumerables, and IO streams.
  # Similar to Log but works with streaming data in real-time.
  module Stream
    class << self
      # Stream lines with an info symbol (cyan).
      # @param source [IO, String, Enumerable] data source to stream
      # @param output [IO] output stream
      # @yield [line] optional block called for each line
      # @return [void]
      def info(source, output: $stdout, &block)
        stream_with_symbol(source, Symbols::S_INFO, :cyan, output, &block)
      end

      # Stream lines with a success symbol (green).
      # @param source [IO, String, Enumerable] data source to stream
      # @param output [IO] output stream
      # @yield [line] optional block called for each line
      # @return [void]
      def success(source, output: $stdout, &block)
        stream_with_symbol(source, Symbols::S_SUCCESS, :green, output, &block)
      end

      # Stream lines with a step symbol (green).
      # @param source [IO, String, Enumerable] data source to stream
      # @param output [IO] output stream
      # @yield [line] optional block called for each line
      # @return [void]
      def step(source, output: $stdout, &block)
        stream_with_symbol(source, Symbols::S_STEP_SUBMIT, :green, output, &block)
      end

      # Stream lines with a warning symbol (yellow).
      # @param source [IO, String, Enumerable] data source to stream
      # @param output [IO] output stream
      # @yield [line] optional block called for each line
      # @return [void]
      def warn(source, output: $stdout, &block)
        stream_with_symbol(source, Symbols::S_WARN, :yellow, output, &block)
      end

      # Stream lines with an error symbol (red).
      # @param source [IO, String, Enumerable] data source to stream
      # @param output [IO] output stream
      # @yield [line] optional block called for each line
      # @return [void]
      def error(source, output: $stdout, &block)
        stream_with_symbol(source, Symbols::S_ERROR, :red, output, &block)
      end

      # Stream lines with a plain bar prefix (no symbol).
      # @param source [IO, String, Enumerable] data source to stream
      # @param output [IO] output stream
      # @return [void]
      def message(source, output: $stdout)
        each_line(source) do |line|
          output.puts "#{Colors.gray(Symbols::S_BAR)}  #{line.chomp}"
          output.flush
        end
      end

      # Stream from a subprocess command.
      # Usage: Clack.stream.command("npm install", type: :info)
      # Returns true on success, false on failure or if command cannot be executed
      def command(cmd, type: :info, output: $stdout)
        IO.popen(cmd, err: %i[child out]) do |io|
          send(type, io, output: output)
        end
        $CHILD_STATUS.success?
      rescue Errno::ENOENT
        false
      end

      private

      def stream_with_symbol(source, symbol, color, output)
        first = true
        each_line(source) do |line|
          line = line.chomp
          if first
            output.puts "#{Colors.send(color, symbol)}  #{line}"
            first = false
          else
            output.puts "#{Colors.gray(Symbols::S_BAR)}  #{line}"
          end
          output.flush
          yield line if block_given?
        end
      end

      def each_line(source, &block)
        case source
        when IO, StringIO
          source.each_line(&block)
        when String
          source.each_line(&block)
        else
          # Enumerable (Array, etc.)
          source.each do |item|
            block.call(item.to_s)
          end
        end
      end
    end
  end
end
