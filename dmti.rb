require 'initialize'

Curses::Ext.init
# Curses::Ext.def_color(:blue, 0, 100, 255)
# Curses::Ext.def_color_pair(:jcarson1, :blue, Curses::COLOR_BLACK)

Dmti::WindowManager.new.run!
