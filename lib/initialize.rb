# Gem/Bundler
require 'rubygems'
require 'bundler/setup'

# Gem Requires
require 'sqlite3'
require 'ruby-lazy-const'
require 'ruby-lazy-config'
require 'curses'

# Other Requires
require 'pathname'

LazyConst::Config.base_dir = './lib'
LazyConfig::Config.base_dir = "/home/#{`whoami`.strip}"

module Curses
  module Key
    RETURN_KEY = 10
    ESCAPE     = 27
    SPACEBAR   = 32
  end

  class Window
    def height
      self.maxy
    end

    def width
      self.maxx
    end

    def miny
      0
    end

    def minx
      0
    end
  end

  class Field
    def insert_char(char)
      return if buffer_full?

      char_as_string = char.chr

      slim_buffer_value = current_buffer
      slim_buffer_value << char_as_string
      full_buffer_value = slim_buffer_value

      set_buffer(0, full_buffer_value)
    end

    def delete_char
      return if buffer_empty?

      # Keep all but the last character.
      new_buffer_value = current_buffer[0..-2]

      # Update the buffer.
      set_buffer(0, new_buffer_value)
    end

    def max_buffer_size=(value)
      @__max_buffer_size = value
    end

    def current_buffer
      buffer(0).rstrip.clone
    end

    private

    def buffer_empty?
      current_buffer.empty?
    end

    def buffer_full?
      current_buffer.size == @__max_buffer_size - 1
    end
  end

  module Ext
    # Initial indexes when defining colors and color_pairs.
    # NOTE: I chose high-ish numbers because I don't want to override
    #   any of the default colors.
    FIRST_COLOR_INDEX = 20
    FIRST_COLOR_PAIR_INDEX = 30

    class << self
      # Initialize curses mode in the terminal. Also set some other options
      # that I pretty much always use.
      def init
        Curses.init_screen
        Curses.start_color
        Curses.use_default_colors
        Curses.raw
        Curses.noecho
        Curses.curs_set(0)
      end

      # Create a color definition by name. Instead of the RGB values being
      # out of 1,000 like default curses, this is out of 255, which is
      # something I'm more familiar with.
      def def_color(name, r, g, b)
        index = next_available_color_pair_index

        @color_name_to_index_mapping ||= {}
        @color_name_to_index_mapping[name.to_sym] = index

        colors_1000 = [r, g, b].map {|value_255| ((value_255 / 255.0) * 1_000).floor}

        Curses.init_color(index, *colors_1000)
      end

      # Create a color_pair definition by name. f_color and b_color are
      # the foreground and background color respectively. They can either
      # be an integer that represents a color that is already defined or
      # it can be a String/Symbol of a color you have defined with
      # def_color() method.
      def def_color_pair(name, f_color, b_color)
        index = next_available_color_pair_index

        @color_pair_name_to_index_mapping ||= {}
        @color_pair_name_to_index_mapping[name.to_sym] = index

        # Try to find the integer representation of the inputs.
        f_color_i = color_lookup(f_color) || f_color.to_i
        b_color_i = color_lookup(b_color) || b_color.to_i

        Curses.init_pair(index, f_color_i, b_color_i)
      end

      # The attribute bits for the color_pair you have previously defined
      # with def_color_pair(). This can be used in curses attr methods
      # like attron(Curses::Ext.color_pair_attr(:pretty_blue) | Curses::A_BOLD).
      def color_pair_attr(name)
         color_pair_lookup(name) << color_attr_bit_shift
      end

      def color_attr(name)
        color_lookup(name) << color_attr_bit_shift
      end

      private

      # Lookup integer value for color with name as defined by def_color().
      def color_lookup(name)
        @color_name_to_index_mapping[name.to_sym]
      end
      
      # Lookup integer value for color_pair with name as defined by
      # def_color_pair().
      def color_pair_lookup(name)
        @color_pair_name_to_index_mapping[name.to_sym] || 0
      end

      # How many bits to shift the color integer value to get the correct
      # curses attribute bits set. This is 8 on my system, maybe thats
      # how it is on all systems, but this method should be able to
      # determine that.
      def color_attr_bit_shift
        @color_attr_bit_shift ||= /(0*)\z/.match(Curses::A_COLOR.to_s(2)).captures[0].size
      end

      # When defining colors with def_color() we need to assign an index
      # for the defined color. This method will get the next available
      # index.
      def next_available_color_index
        if @color_index
          @color_index += 1
        else
          @color_index = FIRST_COLOR_INDEX
        end
      end

      # When defining color_pairs with def_color_pair() we need to
      # assign an index for the defined color_pair. This method will
      # get the next available index.
      def next_available_color_pair_index
        if @color_pair_index
          @color_pair_index += 1
        else
          @color_pair_index = FIRST_COLOR_PAIR_INDEX
        end
      end
    end # class << self

    class Form
      def initialize(
        *field_names,
        **keyword_args
      )
        # Create the Window this form will reside in.
        default_args_for_window = {
          sub_window_top_padding: 1
        }

        keyword_args_for_window = default_args_for_window.merge(
          keyword_args.slice(
            :height,
            :width,
            :top,
            :left,
            :border,
            :title_text,
            :center_title,
            :extend_title_bar
          )
        )

        @ext_window = Curses::Ext::Window.new(
          **keyword_args_for_window
        )
        menu_sub_window = @ext_window.find_or_generate_sub_window

        # Make calculations for field labels and field positions
        longest_field_name = field_names.map(&:size).max
        field_x_offset = longest_field_name + 2
        field_width = @ext_window.width - field_x_offset

        @curses_fields_mapped_by_name = field_names.each_with_index.each_with_object({}) do |(field_name, index), hash|
          # Place each field 1 per line. They will be offset by the longest
          # field name so everything lines up. They will be as big as the
          # remaining width of the window.
          y_pos = index

          field = Curses::Field.new(1, field_width, y_pos, field_x_offset, 0, 0)
          field.max_buffer_size = field_width

          # Use underline as decoration to imply that it is a place to type
          # stuff into.
          field.back = Curses::A_UNDERLINE
          field.fore = Curses::A_UNDERLINE

          hash[field_name] = field
        end

        # Create the actual Curses Form and assign the windows it lives in.
        @curses_form = Curses::Form.new(@curses_fields_mapped_by_name.values)
        @curses_form.set_win(@ext_window.top_level_window)
        @curses_form.set_sub(menu_sub_window)

        @active_field_index = 0

        # We need to show/post the menu before we can write the labels,
        # otherwise the labels won't show up.
        show

        # Write the labels for the fields.
        field_names.each_with_index do |field_name, index|
          y_pos = index

          @ext_window.setpos(y_pos, 0)
          @ext_window << "#{field_name}:"
        end

        # Set the cursor to the first position on the first field.
        first_field_y_pos = 0
        @ext_window.setpos(first_field_y_pos, field_x_offset)
      end

      #
      # Callback Methods
      #

      def define_form_complete_callback(callback_lambda)
        @callbacks ||= {}
        @callbacks[:form_complete] = callback_lambda
      end

      def define_before_input_loop_callback(callback_lambda)
        @callbacks ||= {}
        @callbacks[:before_input_loop] = callback_lambda
      end

      def define_after_input_loop_callback(callback_lambda)
        @callbacks ||= {}
        @callbacks[:after_input_loop] = callback_lambda
      end

      #
      # Input Loop Methods
      #

      def run_input_loop
        return if input_loop_already_running?

        @running_input_loop = true
        keep_alive_input_loop!

        loop do
          if should_kill_input_loop?
            @running_input_loop = false
            break
          end

          ch = getch

          run_before_input_loop_callback!(ch)

          case ch
          when 'A'..'Z'
            insert_char(ch)
          when 'a'..'z'
            insert_char(ch)
          when '0'..'9'
            insert_char(ch)
          when '_'
            insert_char(ch)
          when Curses::Key::UP
            goto_prev_field
          when Curses::Key::DOWN
            goto_next_field
          when Curses::Key::BACKSPACE
            delete_char
          when Curses::Key::RETURN_KEY
            run_form_complete_callback!
          when Curses::Key::F1
            break
          end

          run_after_input_loop_callback!(ch)
        end
      end

      def kill_input_loop!
        @input_loop_death_flag = true
      end

      def keep_alive_input_loop!
        @input_loop_death_flag = false
      end

      #
      # Form Methods
      #

      def show
        @curses_form.post
      end

      #
      # Window Methods
      #

      def getch
        @ext_window.getch
      end

      def refresh
        @ext_window.refresh
      end

      #
      # Metaprogramming - Relay Methods
      #

      def method_missing(method_name, *args, &block)
        @curses_form.send(method_name, *args, &block)
      end

      private

      #
      # Callback Methods
      #

      def run_form_complete_callback!
        return unless @callbacks
        return unless @callbacks[:form_complete]

        @callbacks[:form_complete].call(field_values)
      end

      def run_before_input_loop_callback!(ch)
        return unless @callbacks
        return unless @callbacks[:before_input_loop]

        @callbacks[:before_input_loop].call(ch)
      end

      def run_after_input_loop_callback!(ch)
        return unless @callbacks
        return unless @callbacks[:after_input_loop]

        @callbacks[:after_input_loop].call(ch)
      end

      #
      # Form Methods
      #

      def field_values
        @curses_fields_mapped_by_name.transform_values do |field|
          field.current_buffer
        end
      end

      #
      # Field Methods
      #

      def active_field_name
        @curses_fields_mapped_by_name.keys[@active_field_index]
      end

      def active_field
        @curses_fields_mapped_by_name[active_field_name]
      end

      def insert_char(ch)
        active_field.insert_char(ch)
        driver(Curses::REQ_END_LINE)
      end

      def delete_char
        active_field.delete_char 
        driver(Curses::REQ_END_FIELD)
      end

      def goto_prev_field
        return if on_first_field?

        @active_field_index -= 1

        driver(Curses::REQ_PREV_FIELD)
        driver(Curses::REQ_END_FIELD)
      end

      def goto_next_field
        return if on_last_field?

        @active_field_index += 1

        driver(Curses::REQ_NEXT_FIELD)
        driver(Curses::REQ_END_FIELD)
      end

      def on_first_field?
        @active_field_index.zero?
      end

      def on_last_field?
        @active_field_index == @curses_fields_mapped_by_name.size - 1
      end

      #
      # Input Loop Methods
      #

      def input_loop_already_running?
        @running_input_loop
      end

      def run_input_loop_callback(ch)
        return unless @input_loop_callbacks

        @input_loop_callbacks[ch]&.call(ch)
      end

      def should_kill_input_loop?
        @input_loop_death_flag
      end
    end # Form

    class Menu
      def initialize(
        *items,
        **keyword_args
      )
        # Created the actual Curses objects:
        # 1. Item
        # 2. Menu
        @curses_items_mapped_by_name = items.each_with_object({}) do |item, hash|
          item_name  = item[:name]
          item_attrs = item[:attrs] || {}

          hash[item_name] = {
            curses_item: Curses::Item.new(item_name, ''),
            attrs:       item_attrs
          }
        end
        @curses_menu = Curses::Menu.new(
          @curses_items_mapped_by_name.values.map{|hash| hash[:curses_item]}
        )

        # Create an Ext::Window as a container for this menu.

        # TODO: If given options has border: false, then we don't need top
        # padding I don't think.
        default_args_for_window = {
          sub_window_top_padding: 1
        }

        # Since I didn't explicitly define and keyword args for this
        # constructor, We need to extract certain keys that will be
        # used as keyword arguments to the constructor of Ext::Window
        # object.
        keyword_args_for_window = default_args_for_window.merge(
          keyword_args.slice(
            :height,
            :width,
            :top,
            :left,
            :border,
            :title_text,
            :center_title,
            :extend_title_bar
          )
        )

        # Create the Ext::Window from the options given to the Ext::Menu
        # constructor.
        @ext_window = Curses::Ext::Window.new(
          **keyword_args_for_window
        )

        # Set the window for this menu to be the top_level_window from
        # the Ext::Window.
        @curses_menu.set_win(@ext_window.top_level_window)

        # Set the sub_window for thsi menu to be the sub_window of the
        # Ext::Window object. If there was not already a sub_window generated
        # for the Ext::Window, then we'll generate one here.
        menu_sub_window = @ext_window.find_or_generate_sub_window
        @curses_menu.set_sub(menu_sub_window)

        # The default amount of rows for a curses menu seems to be 16. Here
        # we change it to be the amount of rows in the sub_win that this
        # menu lives in.
        @curses_menu.set_format(menu_sub_window.height, 1)

        @running_input_loop = false

        show
      end

      #
      # Callback Methods
      #

      def def_selected_callback(item_name, callback_lambda)
        @callbacks ||= {}
        @callbacks[:item_selected] ||= {}
        @callbacks[:item_selected][item_name] = callback_lambda
      end

      def define_before_input_loop_callback(callback_lambda)
        @callbacks ||= {}
        @callbacks[:before_input_loop] = callback_lambda
      end

      def define_after_input_loop_callback(callback_lambda)
        @callbacks ||= {}
        @callbacks[:after_input_loop] = callback_lambda
      end

      #
      # Input Loop Methods
      #

      def run_input_loop
        return if input_loop_already_running?

        @running_input_loop = true
        keep_alive_input_loop!

        loop do
          if should_kill_input_loop?
            @running_input_loop = false
            break
          end

          ch = getch

          run_before_input_loop_callback!(ch)

          case ch
          when 'j', Curses::Key::DOWN
            unless last_item_selected?
              down_item
            end
          when 'k', Curses::Key::UP
            unless first_item_selected?
              up_item
            end
          when Curses::Key::RETURN_KEY
            run_selected_item_callback!
          when Curses::Key::F1
            break
          end

          run_after_input_loop_callback!(ch)
        end
      end

      def kill_input_loop!
        @input_loop_death_flag = true
      end

      def keep_alive_input_loop!
        @input_loop_death_flag = false
      end

      #
      # Menu Methods
      #

      def show
        @curses_menu.post
      end

      def hide
        @curses_menu.hide
      end

      #
      # Window Methods
      #

      def getch
        @ext_window.getch
      end

      def refresh
        @ext_window.refresh
      end

      #
      # Metaprogramming - Relay Methods
      #

      def method_missing(method_name, *args, &block)
        @curses_menu.send(method_name, *args, &block)
      end

      private

      #
      # Callback Methods
      #

      def run_selected_item_callback!
        return unless @callbacks
        return unless @callbacks[:item_selected]

        @callbacks.dig(:item_selected, current_item&.name)&.call
      end

      def run_before_input_loop_callback!(ch)
        return unless @callbacks
        return unless @callbacks[:before_input_loop]

        @callbacks[:before_input_loop]&.call(ch)
      end

      def run_after_input_loop_callback!(ch)
        return unless @callbacks
        return unless @callbacks[:after_input_loop]

        @callbacks[:after_input_loop]&.call(ch)
      end

      #
      # Input Loop Methods
      #

      def input_loop_already_running?
        @running_input_loop
      end

      def should_kill_input_loop?
        @input_loop_death_flag
      end

      #
      # Menu Methods
      #

      def first_item_selected?
        current_item == @curses_items_mapped_by_name.values.dig(0, :curses_item)
      end

      def last_item_selected?
        current_item == @curses_items_mapped_by_name.values.dig(-1, :curses_item)
      end
    end

    class Window
      BORDER_SIZE = 1

      def initialize(
        height: nil,
        width: nil,
        top: nil,
        left: nil,
        sub_window_top_padding: 0,
        border: true,
        title_text: 'Title',
        center_title: true,
        extend_title_bar: true
      )
        @parent_window = Curses.stdscr

        # Assign attributes.
        @top_literal = top
        @left_literal = left
        @height_literal = height
        @width_literal = width

        @sub_window_top_padding = sub_window_top_padding

        @border = border
        @title_text = title_text
        @center_title = center_title
        @extend_title_bar = extend_title_bar

        # Calculate dimensions from input.
        @top = calc_absolute_top
        @left = calc_absolute_left
        @height = calc_absolute_height
        @width = calc_absolute_width

        # Create the actual curses window.
        @main_curses_window = Curses::Window.new(
          @height,
          @width,
          @top,
          @left
        )

        # If we have a border, then we'll make a box-less sub_window that lives
        # inside of the main window.
        if has_border?
          @main_curses_window.box(0, 0)

          find_or_generate_sub_window
        end

        effective_window.keypad(true)
        effective_window.scrollok(true)

        # Print the title text in the title area.
        print_title(@title_text)
      end

      #
      # Text Helper Methods
      #

      # nlcr = New Line; Carriage Return
      def nlcr
        if on_bottom_line?
          scroll
          setpos(cury, 0)
        else
          new_y = cury + 1
          new_x = 0

          setpos(new_y, new_x)
        end
      end

      #
      # Curses Attributes Methods
      #

      def with_attron(attr, &block)
        attron(attr)
        block.call
        attroff(attr)
      end

      #
      # Derived/Sub-Window Methods
      #

      def find_or_generate_sub_window
        return @sub_curses_window if @sub_curses_window
        return unless @main_curses_window

        @sub_curses_window =
          if has_border?
            # Derive a window from the main window to fit inside the border
            # created with box().
            @main_curses_window.derwin(
              @main_curses_window.height - (2 * BORDER_SIZE) - @sub_window_top_padding,
              @main_curses_window.width - (2 * BORDER_SIZE),
              BORDER_SIZE + @sub_window_top_padding,
              BORDER_SIZE
            )
          else
            # Derive a window the same exact size, since there is no border.
            @main_curses_window.derwin(
              @main_curses_window.height,
              @main_curses_window.width,
              0,
              0
            )
          end
      end

      #
      # Attribute Getters
      #

      def top_level_window
        @main_curses_window
      end

      #
      #
      #

      def hide
        @main_curses_window.clear
        @sub_curses_window.clear if has_sub_window?
      end

      #
      # Override Curses::Window Methods
      #

      def refresh
        @main_curses_window.refresh
        @sub_curses_window.refresh if has_sub_window?
      end

      #
      # Metaprogramming - Relay Methods
      #

      def method_missing(method_name, *args, &block)
        effective_window.send(method_name, *args, &block)
      end

      #
      # Debugging Methods
      #

      def debug_print_stats
        objs = %i[main_curses_window]
        objs.push(:sub_curses_window) if has_sub_window?

        attrs = %i[
          begy
          begx
          miny
          minx
          maxy
          maxx
          height
          width
        ]

        objs.each do |object_name|
          obj = instance_variable_get("@#{object_name}")

          attrs.each do |attr_name|
            val = obj.send(attr_name)

            addstr(sprintf("%s %s", "#{object_name}.#{attr_name}", val.to_s))
            nlcr
          end
        end

      end

      private

      #
      # Window Wrapper Management Methods
      #

      def print_title(title)
        return unless has_border?

        @main_curses_window.attron(Curses::A_STANDOUT)

        if center_title?
          # Figure out how much whitespace should go on the left and right
          # of the string so we know where to place the string so it appears
          # centered.
          total_ws_chars = @sub_curses_window.width - title.length 
          left_ws_chars = (total_ws_chars / 2.0).floor
          right_ws_chars = (total_ws_chars / 2.0).ceil

          if extended_title_bar?
            # Add whitespace chars to the title on left and right to
            # be centered.
            my_title_text = (' ' * left_ws_chars) + title + (' ' * right_ws_chars)

            @main_curses_window.setpos(0, BORDER_SIZE)
            @main_curses_window << my_title_text
          else
            # Set the position based on how much whitespace should be on the
            # left of the string, even though we are not outputing any white
            # space chars.
            @main_curses_window.setpos(0, BORDER_SIZE + left_ws_chars)
            @main_curses_window << @title_text
          end
        else
          if extended_title_bar?
            # Add whitespace until the end of the title space.
            my_title_text = title + (' ' * (@sub_curses_window.width - title.size))

            @main_curses_window.setpos(0, BORDER_SIZE)
            @main_curses_window << my_title_text
          else
            # Just print the string as is in the top left of the title area.
            @main_curses_window.setpos(0, BORDER_SIZE)
            @main_curses_window << @title_text
          end
        end

        @main_curses_window.attroff(Curses::A_STANDOUT)
      end

      def effective_window
        has_sub_window? ? @sub_curses_window : @main_curses_window
      end

      #
      # Dimension Methods
      #
      
      def on_bottom_line?
        cury == maxy - 1
      end
      
      # We can recieve a fractional number for dimensions and positions.
      # This will interpret those numbers such as 0.5 as being half the
      # size or positioned halfway into the parent window.
      def calc_absolute_top
        if @top_literal
          if @top_literal.is_a?(Float) || @top_literal.is_a?(Rational)
            @parent_window.begy + (@parent_window.maxy * @top_literal).floor
          else
            @top_literal
          end
        else
          @parent_window.begy
        end
      end

      def calc_absolute_left
        if @left_literal
          if @left_literal.is_a?(Float) || @left_literal.is_a?(Rational)
            @parent_window.begx + (@parent_window.maxx * @left_literal).floor
          else
            @left_literal
          end
        else
          @parent_window.begx
        end
      end

      def calc_absolute_height
        if @height_literal
          if @height_literal.is_a?(Float) || @height_literal.is_a?(Rational)
            (@parent_window.height * @height_literal).floor
          else
            @height_literal
          end
        else
          @parent_window.height
        end
      end

      def calc_absolute_width
        if @width_literal
          if @width_literal.is_a?(Float) || @width_literal.is_a?(Rational)
            (@parent_window.width * @width_literal).floor
          else
            @width_literal
          end
        else
          @parent_window.width
        end
      end

      #
      # Question Methods
      #

      def center_title?
        @center_title
      end

      def extended_title_bar?
        @extend_title_bar
      end

      def has_sub_window?
        @sub_curses_window
      end

      def has_border?
        @border
      end
    end
  end
end
