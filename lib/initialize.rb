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

    class Window
      BORDER_SIZE = 1

      def initialize(
        height=Curses.stdscr.maxy,
        width=Curses.stdscr.maxx,
        top=0,
        left=0,
        border: true,
        title_text: 'Title',
        center_title: true,
        extend_title_bar: true
      )
        # Assign attributes.
        @height = height
        @width = width
        @top = top
        @left = left
        @border = border
        @title_text = title_text
        @center_title = center_title
        @extend_title_bar = extend_title_bar

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
          @sub_curses_window = Curses::Window.new(
            @main_curses_window.height - (2 * BORDER_SIZE),
            @main_curses_window.width - (2 * BORDER_SIZE),
            @main_curses_window.begy + BORDER_SIZE,
            @main_curses_window.begx + BORDER_SIZE
          )

          @sub_curses_window.keypad(true)
        else
          @main_curses_window.keypad(true)
        end

        set_title(@title_text)
      end

      def set_title(title)
        return unless has_border?

        effective_title_text =
          if extended_title_bar?
            title + (' ' * (@sub_curses_window.width - title.size))
          else
            @title_text
          end

        @main_curses_window.setpos(0, BORDER_SIZE)
        @main_curses_window.attron(Curses::A_STANDOUT)
        @main_curses_window << effective_title_text
        @main_curses_window.attroff(Curses::A_STANDOUT)
      end

      # Refresh all windows this wrapper has.
      def refresh
        @main_curses_window.refresh
        @sub_curses_window.refresh if has_sub_window?
      end

      def nlcr
        new_y = cury + 1
        new_x = 0

        setpos(new_y, new_x)
      end

      # Relay any methods to the Curses::Window object.
      def method_missing(method_name, *args, &block)
        if has_sub_window?
          @sub_curses_window.send(method_name, *args, &block)
        else
          @main_curses_window.send(method_name, *args, &block)
        end
      end

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
