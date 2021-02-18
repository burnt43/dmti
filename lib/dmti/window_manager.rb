module Dmti
  class WindowManager
    def initialize
      @menu = Curses::Ext::Menu.new(
        'Song List',
        'Scan Files',
        width: 0.3,
        title_text: 'Menu'
      )

      @song_list_window = Curses::Ext::Window.new(
        width: 0.7,
        left: 0.3,
        title_text: 'Song List'
      )
    end

    def run!
      @menu.show
      @menu.refresh
      @song_list_window.refresh

      loop do
        ch = @menu.getch

        case ch
        when Curses::Key::F1
          break
        end
      end
    end

    private
  end
end
