# frozen_string_literal: true

module Clack
  module Prompts
    # Multiple-selection prompt with options organized into named groups.
    #
    # Navigate with arrow keys or j/k. Toggle selection with Space.
    # Groups can optionally be toggled as a whole when +selectable_groups+ is enabled.
    #
    # @example Basic usage
    #   features = Clack.group_multiselect(
    #     message: "Select features",
    #     options: [
    #       { label: "Frontend", options: %w[hotwire stimulus] },
    #       { label: "Backend", options: %w[sidekiq solid_queue] }
    #     ]
    #   )
    #
    # @example With selectable groups and spacing
    #   features = Clack.group_multiselect(
    #     message: "Select features",
    #     options: [
    #       { label: "Frontend", options: [
    #         { value: "hotwire", label: "Hotwire" },
    #         { value: "stimulus", label: "Stimulus" }
    #       ]},
    #       { label: "Background", options: [
    #         { value: "sidekiq", label: "Sidekiq" },
    #         { value: "solid_queue", label: "Solid Queue" }
    #       ]}
    #     ],
    #     selectable_groups: true,
    #     group_spacing: 1
    #   )
    #
    class GroupMultiselect < Core::Prompt
      include Core::SelectionManager

      # @param message [String] the prompt message
      # @param options [Array<Hash>] groups, each with :label and :options (Array<Hash, String>)
      # @param initial_values [Array] values to pre-select
      # @param required [Boolean] require at least one selection (default: true)
      # @param selectable_groups [Boolean] allow toggling all options in a group at once (default: false)
      # @param group_spacing [Integer] number of blank lines between groups (default: 0)
      # @param cursor_at [Object, nil] value to position cursor at initially
      # @param opts [Hash] additional options passed to {Core::Prompt}
      def initialize(
        message:,
        options:,
        initial_values: [],
        required: true,
        selectable_groups: false,
        group_spacing: 0,
        cursor_at: nil,
        **opts
      )
        if opts.key?(:initial_value)
          raise ArgumentError, "GroupMultiselect uses initial_values: (plural), not initial_value:"
        end
        super(message:, **opts)
        @groups = normalize_groups(options)
        @flat_items = build_flat_items
        valid_values = Set.new(@flat_items.select { |item| item[:type] == :option }.map { |item| item[:value] })
        @selected = Set.new(initial_values) & valid_values
        @required = required
        @selectable_groups = selectable_groups
        @group_spacing = group_spacing
        @option_index = find_initial_cursor(cursor_at)
        update_value
      end

      protected

      def handle_input(_key, action)
        case action
        when :up then move_cursor(-1)
        when :down then move_cursor(1)
        when :space then toggle_current
        end
      end

      def submit
        return unless validate_selection

        super
      end

      def build_frame
        lines = []
        lines << "#{bar}\n"
        lines << "#{symbol_for_state}  #{@message}\n"
        lines << help_line

        prev_was_group = false
        @flat_items.each_with_index do |item, idx|
          is_group = item[:type] == :group
          is_last_in_group = item[:last_in_group]

          # Add group spacing before groups (except first)
          if is_group && !prev_was_group && idx.positive? && @group_spacing.positive?
            @group_spacing.times { lines << "#{active_bar}\n" }
          end

          lines << if is_group
            group_display(item, idx == @option_index)
          else
            option_display(item, idx == @option_index, is_last_in_group)
          end

          prev_was_group = is_group
        end

        lines << "#{bar_end}\n"

        lines[-1] = "#{Colors.yellow(Symbols::S_BAR_END)}  #{Colors.yellow(@error_message)}\n" if @state == :error

        lines.join
      end

      def final_display = selected_options.map { |o| o[:label] }.join(", ")

      private

      def normalize_groups(options) = options.map { |group| normalize_group(group) }

      def normalize_group(group)
        {
          label: group[:label] || group[:group],
          options: group[:options].map { |opt| normalize_option(opt) }
        }
      end

      def normalize_option(opt)
        Core::OptionsHelper.normalize_option(opt)
      end

      def build_flat_items = @groups.flat_map { |group| flatten_group(group) }

      def flatten_group(group)
        group_item = {type: :group, label: group[:label], options: group[:options]}
        option_items = group[:options].each_with_index.map do |opt, idx|
          {
            type: :option,
            value: opt[:value],
            label: opt[:label],
            hint: opt[:hint],
            disabled: opt[:disabled],
            group: group,
            last_in_group: idx == group[:options].length - 1
          }
        end
        [group_item, *option_items]
      end

      def selected_options
        @flat_items.select { |item| item[:type] == :option && @selected.include?(item[:value]) }
      end

      def find_initial_cursor(cursor_at)
        return 0 if @flat_items.empty?

        if cursor_at
          idx = @flat_items.find_index { |item| item[:value] == cursor_at }
          return idx if idx
        end

        @flat_items.find_index { |item| can_select?(item) } || 0
      end

      def can_select?(item)
        return false if item[:disabled]
        return @selectable_groups if item[:type] == :group

        true
      end

      def move_cursor(delta)
        new_cursor = @option_index
        attempts = @flat_items.length

        loop do
          new_cursor = (new_cursor + delta) % @flat_items.length
          attempts -= 1
          break if can_select?(@flat_items[new_cursor]) || attempts <= 0
        end

        @option_index = new_cursor
      end

      def toggle_current
        item = @flat_items[@option_index]
        return unless can_select?(item)

        if item[:type] == :group
          toggle_group(item)
        else
          toggle_option(item)
        end
        update_value
      end

      def toggle_group(group_item)
        group_values = group_item[:options].reject { |o| o[:disabled] }.map { |o| o[:value] }
        all_selected = group_values.all? { |v| @selected.include?(v) }

        if all_selected
          group_values.each { |v| @selected.delete(v) }
        else
          group_values.each { |v| @selected.add(v) }
        end
      end

      def toggle_option(item)
        toggle_value(item[:value])
      end

      def update_value = update_selection_value

      def group_display(item, active)
        if @selectable_groups
          all_selected = item[:options].reject { |o| o[:disabled] }.all? { |o| @selected.include?(o[:value]) }
          checkbox = all_selected ? Colors.green(Symbols::S_CHECKBOX_SELECTED) : Colors.dim(Symbols::S_CHECKBOX_INACTIVE)
          label = active ? item[:label] : Colors.dim(item[:label])
          "#{active_bar}  #{checkbox} #{label}\n"
        else
          "#{active_bar}  #{Colors.dim(item[:label])}\n"
        end
      end

      def option_display(item, active, is_last)
        selected = @selected.include?(item[:value])
        prefix = if @selectable_groups
          "#{is_last ? Symbols::S_BAR_END : Symbols::S_BAR} "
        else
          "  "
        end
        hint = (item[:hint] && active) ? " #{Colors.dim("(#{item[:hint]})")}" : ""

        if item[:disabled]
          "#{active_bar}  #{Colors.dim(prefix)}#{Colors.dim(Symbols::S_CHECKBOX_INACTIVE)} #{Colors.strikethrough(Colors.dim(item[:label]))}\n"
        elsif active && selected
          "#{active_bar}  #{Colors.dim(prefix)}#{Colors.green(Symbols::S_CHECKBOX_SELECTED)} #{item[:label]}#{hint}\n"
        elsif active
          "#{active_bar}  #{Colors.dim(prefix)}#{Colors.cyan(Symbols::S_CHECKBOX_ACTIVE)} #{item[:label]}#{hint}\n"
        elsif selected
          "#{active_bar}  #{Colors.dim(prefix)}#{Colors.green(Symbols::S_CHECKBOX_SELECTED)} #{Colors.dim(item[:label])}\n"
        else
          "#{active_bar}  #{Colors.dim(prefix)}#{Colors.dim(Symbols::S_CHECKBOX_INACTIVE)} #{Colors.dim(item[:label])}\n"
        end
      end
    end
  end
end
