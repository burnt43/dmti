module Dmti
  class WindowManager
    def initialize
      menu_x_division                 = 0.3
      song_list_y_relative_division   = 0.8
      status_y_division               = 0.9

      @state = :main_menu_active
      @current_filename = nil

      # Left Side
      @main_menu = Curses::Ext::Menu.new(
        {name: 'Song List'},
        {name: 'Scan Files'},
        width:      menu_x_division,
        height:     song_list_y_relative_division,
        title_text: 'Menu'
      )

      @song_record_menu = Curses::Ext::Menu.new(
        {name: 'Add Song to File'},
        {name: 'Next File'},
        top:        song_list_y_relative_division,
        height:     status_y_division - song_list_y_relative_division,
        width:      menu_x_division,
        title_text: 'Song Mapper'
      )

      # Right Side
      @song_list_window = Curses::Ext::Window.new(
        left:       menu_x_division,
        height:     song_list_y_relative_division,
        width:      1 - menu_x_division,
        title_text: 'Song List'
      )

      @song_record_form = Curses::Ext::Form.new(
        'Song Name',
        'Page Number',
        top:        song_list_y_relative_division,
        left:       menu_x_division,
        height:     status_y_division - song_list_y_relative_division,
        width:      1 - menu_x_division,
        title_text: 'Song Mapper'
      )

      # Bottom
      @status_window = Curses::Ext::Window.new(
        top:        status_y_division,
        height:     1 - status_y_division,
        title_text: 'Status'
      )

      # Define Callbacks
      @main_menu.def_selected_callback('Song List', ->{
        print_debug(Random.rand(100000))
      })

      @main_menu.def_selected_callback('Scan Files', ->{
        case @state
        when :main_menu_active
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
            print_info("Current File: #{@current_filename}")
            refresh_status_window

            # Refresh to the cursor will be active on this window to let
            # the user know to enter data.
            @song_record_form.refresh
            @song_record_form.run_input_loop
          end
        end
      })

      @song_record_form.define_input_loop_callback('a', ->(ch) {
        mapping = @song_record_form.instance_eval { @curses_fields_mapped_by_name }
        mapping.each do |name, field|
          print_debug("Field(#{name}): #{field.buffer(0).strip.size} #{field.buffer(0).strip}")
        end

        refresh_status_window
      })
    end

    def run!
      @main_menu.refresh
      @song_record_menu.refresh
      @song_record_form.refresh
      @status_window.refresh

      @song_list_window.setpos(0,0)
      @song_list_window << "@main_menu.item_count: #{@main_menu.item_count}"
      @song_list_window.nlcr
      @song_list_window << "@main_menu.opts: #{@main_menu.opts}"
      @song_list_window.nlcr
      @song_list_window << "@main_menu.scale: #{@main_menu.scale}"
      @song_list_window.refresh


      @main_menu.run_input_loop
    end

    private

    def refresh_status_window
      @status_window.refresh
    end

    def print_debug(msg)
      print_msg(msg, type_name: 'DEBUG', type_color_pair_name: :debug)
    end

    def print_info(msg)
      print_msg(msg, type_name: 'INFO', type_color_pair_name: :info)
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
