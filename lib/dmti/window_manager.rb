module Dmti
  class WindowManager
    def initialize
      menu_x_division               = 0.3
      status_y_division             = 0.8
      song_list_y_relative_division = 0.6

      @menu = Curses::Ext::Menu.new(
        {name: 'Song List'},
        {name: 'Scan Files'},
        width:      menu_x_division,
        height:     status_y_division,
        title_text: 'Menu'
      )

      # @form_menu = Curses::Ext::Menu.new(
      #   {name: 'Add Song to File'},
      #   {name: 'Next Filh'}
      # )

      @song_list_window = Curses::Ext::Window.new(
        left:       menu_x_division,
        height:     song_list_y_relative_division,
        width:      (1 - menu_x_division),
        title_text: 'Song List'
      )

      @form_window = Curses::Ext::Form.new(
        'Song Name',
        'Page Number',
        top:        song_list_y_relative_division,
        left:       menu_x_division,
        height:     (status_y_division - song_list_y_relative_division),
        width:      (1 - menu_x_division),
        title_text: 'Song Mapper'
      )

      @status_window = Curses::Ext::Window.new(
        top:        status_y_division,
        height:     (1 - status_y_division),
        title_text: 'Status'
      )

      @menu.def_selected_callback('Song List', ->{
        print_debug(Random.rand(100000))
      })

      @menu.def_selected_callback('Scan Files', ->{
      })
    end

    def run!
      @menu.refresh
      @form_window.refresh
      @status_window.refresh

      @song_list_window.setpos(0,0)
      @song_list_window << "@menu.item_count: #{@menu.item_count}"
      @song_list_window.nlcr
      @song_list_window << "@menu.opts: #{@menu.opts}"
      @song_list_window.nlcr
      @song_list_window << "@menu.scale: #{@menu.scale}"
      @song_list_window.refresh


      @menu.run_input_loop
    end

    private

    def print_debug(msg)
      @status_window.nlcr
      @status_window << '['
      @status_window.with_attron(Curses::Ext.color_pair_attr(:debug)) do
        @status_window << 'DEBUG'
      end
      @status_window << "] - #{msg}"
      @status_window.refresh
    end
  end
end
