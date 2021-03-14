module Dmti
  class WindowManager
    def initialize
      menu_options = [
        {name: 'Song List', attrs: {}},
        {name: 'Scan Files', attrs: {}},
      ]

      @menu = Curses::Ext::Menu.new(
        *menu_options,
        width: 0.3,
        title_text: 'Menu'
      )

      @song_list_window = Curses::Ext::Window.new(
        width: 0.7,
        height: 0.8,
        left: 0.3,
        title_text: 'Song List'
      )

      @form_window = Curses::Ext::Form.new(
        'Song Name',
        'Page Number',
        top: 0.8,
        height: 0.2,
        width: 0.7,
        left: 0.3,
        title_text: 'Song Mapper'
      )

      @menu.def_selected_callback('Song List', ->{
      })

      @menu.def_selected_callback('Scan Files', ->{
      })
    end

    def run!
      @menu.refresh

      @song_list_window.setpos(0,0)
      @song_list_window << "@menu.item_count: #{@menu.item_count}"
      @song_list_window.nlcr
      @song_list_window << "@menu.opts: #{@menu.opts}"
      @song_list_window.nlcr
      @song_list_window << "@menu.scale: #{@menu.scale}"
      @song_list_window.refresh

      @form_window.refresh

      @menu.run_input_loop
    end

    private
  end
end
