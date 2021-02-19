module Dmti
  class WindowManager
    def initialize
      menu_option_names = [
        'Song List',
        'Scan Files'
      ]

      @menu = Curses::Ext::Menu.new(
        *menu_option_names,
        width: 0.3,
        title_text: 'Menu'
      )

      @song_list_window = Curses::Ext::Window.new(
        width: 0.7,
        left: 0.3,
        title_text: 'Song List'
      )

      @menu.def_selected_callback('Song List', ->{
        @menu.kill_input_loop!
      })

      @menu.def_selected_callback('Scan Files', ->{
        @menu.kill_input_loop!
      })
    end

    def run!
      @menu.refresh
      @menu.show

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
  end
end
