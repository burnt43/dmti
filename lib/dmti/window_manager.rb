module Dmti
  class WindowManager
    def initialize
      option_names = [
        'Song List',
        'Scan Files'
      ]
      48.times {|n| option_names.push("Option #{n}")}

      @menu = Curses::Ext::Menu.new(
        *option_names,
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
      @song_list_window.setpos(0,0)
      @song_list_window << "@menu.item_count: #{@menu.item_count}"
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
