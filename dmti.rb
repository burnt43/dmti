require 'initialize'

Curses::Ext.init

Curses::Ext.def_color(:test_fg, 100, 200, 230)
Curses::Ext.def_color(:test_bg, 50, 50, 50)
Curses::Ext.def_color_pair(:test, :test_fg, :test_bg)

Dmti::WindowManager.new.run!
