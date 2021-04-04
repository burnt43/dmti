module Dmti
  class WindowManager
    def initialize
      menu_x_division                 = 0.3
      song_list_y_relative_division   = 0.5
      status_y_division               = 0.7

      @current_filename = nil

      # Left Side
      @main_menu = Curses::Ext::Menu.new(
        {name: 'Song List'},
        {name: 'Scan Files'},
        {name: 'Quit'},
        width:                menu_x_division,
        height:               song_list_y_relative_division,
        title_text:           'Menu',
        highlight_color_pair: :window_highlight
      )

      @song_map_menu = Curses::Ext::Menu.new(
        {name: 'Add Song to File'},
        {name: 'Next File'},
        top:                  song_list_y_relative_division,
        height:               status_y_division - song_list_y_relative_division,
        width:                menu_x_division,
        title_text:           'Song Mapper',
        highlight_color_pair: :window_highlight
      )

      # Right Side

      song_menu_items = Dmti.songs_in_db.map do |song_name, filename, page_index|
        {
          name: song_name,
          attrs: {
            filename:   filename,
            page_index: page_index
          }
        }
      end

      @song_menu = Curses::Ext::Menu.new(
        *song_menu_items,
        left:                 menu_x_division,
        height:               song_list_y_relative_division,
        width:                1 - menu_x_division,
        title_text:           'Song List',
        highlight_color_pair: :window_highlight
      )

      @song_form = Curses::Ext::Form.new(
        'Song Name',
        'Page Number',
        top:                  song_list_y_relative_division,
        left:                 menu_x_division,
        height:               status_y_division - song_list_y_relative_division,
        width:                1 - menu_x_division,
        title_text:           'Song Mapper',
        highlight_color_pair: :window_highlight
      )

      # Bottom
      @status_window = Curses::Ext::Window.new(
        top:        status_y_division,
        height:     1 - status_y_division,
        title_text: 'Status'
      )

      # Define Callbacks
      @main_menu.def_selected_callback('Song List', ->{
        unfocus_main_menu
        focus_song_menu
      })

      @main_menu.def_selected_callback('Scan Files', ->{
        unfocus_main_menu

        # Stop reading in put on the main_menu.
        @main_menu.kill_input_loop!

        # Find the files that are not added to the DB.
        print_debug('Scanning for missing files...')
        missing_filenames = Dmti.filenames_missing_in_database

        # Show how many files we've found.
        print_info("Found #{missing_filenames.size} new files.")

        #
        missing_filenames.each do |missing_filename|
          @current_filename = missing_filename
          print_info("Current File: #{@current_filename}", refresh: true)

          focus_song_form
        end
      })

      @main_menu.def_selected_callback('Quit', ->{
        @main_menu.kill_input_loop!
      })

      #
      # song_menu callbacks
      #

      # Add a way to escape back to the main_menu.
      @song_menu.define_after_input_loop_callback ->(ch) {
        case ch
        when Curses::Key::ESCAPE, Curses::Key::LEFT
          unfocus_song_menu
          focus_main_menu
        end
      }

      #
      # song_map_menu callbacks
      #

      @song_map_menu.def_selected_callback('Add Another Song', -> {
      })

      @song_map_menu.def_selected_callback('Next File', -> {
      })

      #
      # song_form callbacks
      #

      # NOTE: This is jsut debugging what curses gives to use from getch.
      @song_form.define_before_input_loop_callback ->(ch) {
        if ch.is_a?(String)
          print_debug("typed(String): #{ch}(#{ch.unpack('C*')[0]})", refresh: true)
        elsif ch.is_a?(Integer)
          print_debug("typed(Integer): (#{ch})", refresh: true)
        end

        focus_song_form
      }

      # Add a way to escape back to the main_menu.
      @song_form.define_after_input_loop_callback ->(ch) {
        case ch
        when Curses::Key::ESCAPE, Curses::Key::LEFT
          # TODO: add a clear form method to clear the values.
          unfocus_song_form
          focus_main_menu
        else
          buffer = @song_form.send(:active_field).instance_eval { @parallel_buffer }
          print_debug("buffer: (#{buffer})", refresh: true)
          focus_song_form
        end
      }

      # Add a way to process when the user completes the song_form.
      @song_form.define_form_complete_callback ->(field_values) {
        # TODO: validate the field_values

        # TODO: be able to highlight field value labels when there is an error

        # TODO: fix this method. the name is different now i think.
        # create_song_mapping(field_values)

        unfocus_song_form

        print_debug(field_values.to_s, refresh: true)

        focus_song_map_menu
      }
    end

    def run!
      @song_menu.refresh
      @song_map_menu.refresh
      @song_form.refresh
      @status_window.refresh

      focus_main_menu
    end

    private

    def create_song_mapping(field_values)
      column_attributes = {
        name:       field_values['Song Name'],
        page_index: field_values['Page Number'],
        filename:   @current_filename
      }

      Dmti.create_song_mapping(column_attributes)
    end

    #
    # Focus/Unfocus main_menu Methods
    #

    def unfocus_main_menu
      @main_menu.kill_input_loop!
      @main_menu.draw_border(highlight: false)
      @main_menu.refresh
    end

    def focus_main_menu
      Curses.curs_set(0)
      @main_menu.keep_alive_input_loop!
      @main_menu.draw_border(highlight: true)
      @main_menu.refresh
      @main_menu.run_input_loop
    end

    #
    # Focus/Unfocus song_menu
    #

    def unfocus_song_menu
      @song_menu.kill_input_loop!
      @song_menu.draw_border(highlight: false)
      @song_menu.refresh
    end

    def focus_song_menu
      Curses.curs_set(0)
      @song_menu.keep_alive_input_loop!
      @song_menu.draw_border(highlight: true)
      @song_menu.refresh
      @song_menu.run_input_loop
    end

    #
    # Focus/Unfocus song_form Methods
    #

    def unfocus_song_form
      @song_form.kill_input_loop!
      @song_form.draw_border(highlight: false)
      @song_form.refresh
    end

    def focus_song_form
      Curses.curs_set(1)
      @song_form.keep_alive_input_loop!
      @song_form.draw_border(highlight: true)
      @song_form.refresh
      @song_form.run_input_loop
    end

    #
    # Focus/Unfocus song_map Methods
    #

    def unfocus_song_map_menu
      @song_map_menu.kill_input_loop!
      @song_map_menu.draw_border(highlight: false)
      @song_map_menu.refresh
    end

    def focus_song_map_menu
      Curses.curs_set(0)
      @song_map_menu.keep_alive_input_loop!
      @song_map_menu.draw_border(highlight: true)
      @song_map_menu.refresh
      @song_map_menu.run_input_loop
    end

    #
    # Status Window Methods
    #

    def refresh_status_window
      Curses.curs_set(0)
      @status_window.refresh
    end

    #
    # Print to Status Window Methods
    #

    def print_debug(msg, refresh: false)
      print_msg(msg, type_name: 'DEBUG', type_color_pair_name: :debug)

      refresh_status_window if refresh
    end

    def print_info(msg, refresh: false)
      print_msg(msg, type_name: 'INFO', type_color_pair_name: :info)

      refresh_status_window if refresh
    end

    def print_msg(msg, type_name: nil, type_color_pair_name: nil)
      @status_window.nlcr

      if type_name
        @status_window << '['

        if type_color_pair_name
          @status_window.with_attron(Curses::Ext.color_pair_attr(type_color_pair_name)) do
            @status_window << type_name.to_s
          end
        else
          @status_window << type_name.to_s
        end

        @status_window << '] - '
      end

      @status_window << msg.to_s
    end
  end
end
