require 'initialize'

Curses::Ext.init
Curses::Ext.def_color(:blue, 0, 100, 255)
Curses::Ext.def_color_pair(:jcarson1, :blue, Curses::COLOR_BLACK)

menu = Curses::Ext::Menu.new(
  nil, nil, nil, nil,
  'Item 1',
  'Item 2'
)
menu.show
menu.refresh

loop do
  ch = menu.getch

  case ch
  when Curses::Key::F1
    break
  end
end
