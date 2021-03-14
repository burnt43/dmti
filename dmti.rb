require 'initialize'

Curses::Ext.init

Curses::Ext.def_color(:debug_fg, 230, 220, 50)
Curses::Ext.def_color(:debug_bg, 0, 0, 0)
Curses::Ext.def_color_pair(:debug, :debug_fg, :debug_bg)

Dmti::WindowManager.new.run!
