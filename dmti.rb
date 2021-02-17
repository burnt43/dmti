require 'initialize'

Curses::Ext.init
Curses::Ext.def_color(:blue, 0, 100, 255)
Curses::Ext.def_color_pair(:jcarson1, :blue, Curses::COLOR_BLACK)

main_window = Curses::Ext::Window.new

main_window.debug_print_stats
main_window.refresh

loop do
  ch = main_window.getch

  case ch
  when Curses::Key::F1
    break
  end
end
