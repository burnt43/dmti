require 'initialize'

Curses::Ext.init

# Debug
Curses::Ext.def_color(:debug_fg, 230, 220, 50)
Curses::Ext.def_color(:debug_bg, 0, 0, 0)
Curses::Ext.def_color_pair(:debug, :debug_fg, :debug_bg)

# Info
Curses::Ext.def_color(:info_fg, 150, 30, 222)
Curses::Ext.def_color(:info_bg, 0, 0, 0)
Curses::Ext.def_color_pair(:info, :info_fg, :info_bg)

# Window Highlight
Curses::Ext.def_color(:window_highlight_fg, 30, 150, 230)
Curses::Ext.def_color(:window_highlight_bg, 0, 0, 0)
Curses::Ext.def_color_pair(:window_highlight, :window_highlight_fg, :window_highlight_bg)

Dmti::WindowManager.new.run!
