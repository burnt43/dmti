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

  module Ext
    FIRST_COLOR_INDEX = 20
    FIRST_COLOR_PAIR_INDEX = 30

    class << self
      def init
        Curses.init_screen
        Curses.start_color
        Curses.use_default_colors
        Curses.raw
        Curses.noecho
        Curses.curs_set(0)
      end

      def def_color(name, r, g, b)
        index = next_available_color_pair_index

        @color_name_to_index_mapping ||= {}
        @color_name_to_index_mapping[name.to_sym] = index

        colors_1000 = [r, g, b].map {|value_255| ((value_255 / 255.0) * 1_000).floor}

        Curses.init_color(index, *colors_1000)
      end

      def def_color_pair(name, f_color, b_color)
        index = next_available_color_pair_index

        @color_pair_name_to_index_mapping ||= {}
        @color_pair_name_to_index_mapping[name.to_sym] = index

        f_color_i = color_lookup(f_color)
        b_color_i = color_lookup(b_color)

        Curses.init_pair(index, f_color_i, b_color_i)
      end

      def color_pair_attr(name)
         color_pair_lookup(name) << color_attr_bit_shift
      end

      private

      def color_lookup(name)
        if name.is_a?(String) || name.is_a?(Symbol)
          key = name.to_sym
          @color_name_to_index_mapping[key]
        else
          name
        end
      end

      def color_pair_lookup(name)
        @color_pair_name_to_index_mapping[name.to_sym] || 0
      end

      def color_attr_bit_shift
        @color_attr_bit_shift ||= /(0*)\z/.match(Curses::A_COLOR.to_s(2)).captures[0].size
      end

      def next_available_color_index
        if @color_index
          @color_index += 1
        else
          @color_index = FIRST_COLOR_INDEX
        end
      end

      def next_available_color_pair_index
        if @color_pair_index
          @color_pair_index += 1
        else
          @color_pair_index = FIRST_COLOR_PAIR_INDEX
        end
      end
    end

    class Menu
      def initialize(
        *item_names,
        **keyword_args
      )
        @curses_items_mapped_by_name = item_names.each_with_object({}) do |item_name, hash|
          hash[item_name] = Curses::Item.new(item_name, '')
        end

        @curses_menu = Curses::Menu.new(@curses_items_mapped_by_name.values)

        # TODO: If given options has border: false, then we don't need top
        # padding I don't think.
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

        @curses_menu.set_win(@ext_window.main_curses_window)
        @curses_menu.set_sub(@ext_window.find_or_generate_sub_window)
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
        # @ext_window.sub_curses_window.box('o', 'o')
        @ext_window.refresh
      end

      #
      # Metaprogramming - Relay Methods
      #

      def method_missing(method_name, *args, &block)
        @curses_menu.send(method_name, *args, &block)
      end
    end

    class Window
      BORDER_SIZE = 1

      attr_reader :main_curses_window
      attr_reader :sub_curses_window

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

        # If we have a border, then we'll make a box-less subwindow that lives
        # inside of the main window.
        if has_border?
          @main_curses_window.box(0, 0)

          find_or_generate_sub_window
          @sub_curses_window.keypad(true)
        else
          @main_curses_window.keypad(true)
        end

        print_title(@title_text)
      end

      #
      # Text Helper Methods
      #

      # nlcr = New Line; Carriage Return
      def nlcr
        new_y = cury + 1
        new_x = 0

        setpos(new_y, new_x)
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
      # Override Curses::Window Methods
      #

      # Refresh all windows this wrapper has.
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
