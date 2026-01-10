# frozen_string_literal: true

module Clack
  module Prompts
    # File/directory path selector with filesystem navigation.
    #
    # Type to filter suggestions from the current directory.
    # Press Tab to autocomplete the selected suggestion.
    # Navigate suggestions with arrow keys.
    #
    # Supports:
    # - Absolute paths (starting with /)
    # - Home directory expansion (~/...)
    # - Relative paths (from root directory)
    # - Directory-only filtering
    #
    # @example Basic usage
    #   path = Clack.path(message: "Select a file")
    #
    # @example Directory picker
    #   dir = Clack.path(
    #     message: "Choose project directory",
    #     only_directories: true,
    #     root: "~/projects"
    #   )
    #
    class Path < Core::Prompt
      include Core::TextInputHelper

      # @param message [String] the prompt message
      # @param root [String] starting/base directory (default: ".")
      # @param only_directories [Boolean] only show directories (default: false)
      # @param max_items [Integer] max visible suggestions (default: 5)
      # @param validate [Proc, nil] validation proc for the final path
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(message:, root: ".", only_directories: false, max_items: 5, **opts)
        super(message:, **opts)
        @root = File.expand_path(root)
        @only_directories = only_directories
        @max_items = max_items
        @value = ""
        @cursor = 0
        @selected_index = 0
        @scroll_offset = 0
        @suggestions = []
        update_suggestions
      end

      protected

      def handle_input(key, action)
        case action
        when :up
          move_selection(-1)
        when :down
          move_selection(1)
        else
          # Tab to autocomplete
          if key == "\t" && !@suggestions.empty?
            autocomplete_selection
          else
            handle_text_input(key)
          end
        end
      end

      def handle_text_input(key)
        return unless super

        @selected_index = 0
        @scroll_offset = 0
        update_suggestions
      end

      def autocomplete_selection
        return if @suggestions.empty?

        @value = @suggestions[@selected_index]
        @cursor = @value.length
        update_suggestions
      end

      def submit
        path = @value.empty? ? @root : resolve_path(@value)

        unless path_within_root?(path)
          @error_message = "Path must be within #{@root}"
          @state = :error
          return
        end

        # Use base class validation helper
        new_state = validate_value(path)
        return @state = new_state unless new_state == :submit

        @value = path
        @state = :submit
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << "#{active_bar}  #{input_display}\n"

        visible_suggestions.each_with_index do |path, idx|
          actual_idx = @scroll_offset + idx
          lines << "#{bar}  #{suggestion_display(path, actual_idx == @selected_index)}\n"
        end

        lines << "#{bar_end}\n"

        validation_lines = validation_message_lines
        if validation_lines.any?
          lines[-1] = validation_lines.first
          lines.concat(validation_lines[1..])
        end

        lines.join
      end

      def build_final_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"

        display = (@state == :cancel) ? Colors.strikethrough(Colors.dim(@value)) : Colors.dim(@value)
        lines << "#{bar}  #{display}\n"

        lines.join
      end

      private

      def update_suggestions
        base_path = resolve_path(@value)

        # Only show suggestions for paths within root
        unless path_within_root?(base_path)
          @suggestions = []
          return
        end

        search_dir = File.directory?(base_path) ? base_path : File.dirname(base_path)
        prefix = File.directory?(base_path) ? "" : File.basename(base_path).downcase

        @suggestions = list_entries(search_dir, prefix)
      rescue SystemCallError
        @suggestions = []
      end

      def list_entries(dir, prefix)
        return [] unless File.directory?(dir)

        entries = Dir.entries(dir) - [".", ".."]
        entries = entries.select { |entry| File.directory?(File.join(dir, entry)) } if @only_directories
        entries = entries.select { |entry| entry.downcase.start_with?(prefix) } unless prefix.empty?
        entries.sort.first(@max_items * 2).map { |entry| format_entry(dir, entry) }
      end

      def format_entry(dir, entry)
        full_path = File.join(dir, entry)
        if full_path == @root || full_path.start_with?("#{@root}/")
          # Show relative path without leading ./
          path = full_path[@root.length..]
          path = path.sub(%r{^/}, "")
          path = entry if path.empty?
        else
          path = full_path
        end
        path += "/" if File.directory?(full_path)
        path
      end

      def resolve_path(input)
        return @root if input.empty?

        path = if input.start_with?("/")
          input
        elsif input.start_with?("~")
          File.expand_path(input)
        else
          File.join(@root, input)
        end

        # Canonicalize to resolve .. and symlinks
        File.expand_path(path)
      end

      def path_within_root?(path)
        expanded = File.expand_path(path)
        expanded == @root || expanded.start_with?("#{@root}/")
      end

      def visible_suggestions
        return @suggestions if @suggestions.length <= @max_items

        @suggestions[@scroll_offset, @max_items]
      end

      def move_selection(delta)
        return if @suggestions.empty?

        @selected_index = (@selected_index + delta) % @suggestions.length
        update_scroll
      end

      def update_scroll
        return unless @suggestions.length > @max_items

        if @selected_index < @scroll_offset
          @scroll_offset = @selected_index
        elsif @selected_index >= @scroll_offset + @max_items
          @scroll_offset = @selected_index - @max_items + 1
        end
      end

      # Override to use @root as placeholder
      def placeholder_display
        return "" if @root.empty?

        first = Colors.inverse(@root[0])
        rest = Colors.dim(@root[1..])
        "#{first}#{rest}"
      end

      def suggestion_display(path, active)
        icon = path.end_with?("/") ? Symbols::S_FOLDER : Symbols::S_FILE
        if active
          "#{Colors.cyan(icon)} #{path}"
        else
          "#{Colors.dim(icon)} #{Colors.dim(path)}"
        end
      end
    end
  end
end
