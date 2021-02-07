require 'initialize'

module Dmti
  Pos = Struct.new(:y, :x) do
    def set(y, x)
      self.y = y
      self.x = x
    end

    def to_args
      [self.y, self.x]
    end

    def to_s
      "(#{self.y}, #{self.x})"
    end

    def inc_y
      self.y += 1
    end

    def inc_x
      self.x += 1
    end
  end
end

pos = Dmti::Pos.new(0,0)

# start curses mode
Curses.init_screen

# take all input
Curses.raw

# don't print out what is typed
Curses.noecho

# set window as the top level window
main_window = Curses.stdscr

# be able to capture arrow keys
main_window.keypad(true)

# set cursor to top left
main_window.setpos(*pos.to_args)

# print out string
main_window.addstr("HELLO, WORLD")

# refresh so the screen draws
main_window.refresh

loop do
  if pos.y >= main_window.maxy - 1
    # NoOp
  else
    pos.inc_y
  end

  main_window.setpos(*pos.to_args)

  ch = main_window.getch
  case ch
  when 'a'
    main_window.addstr("a: #{pos} #{main_window.maxy}")
  when 'b'
    # Turn on Bold [test attron()]
    main_window.addstr('bold on')
    main_window.attron(Curses::A_BOLD)
  when 'B'
    # Turn off Bold [test attroff()]
    main_window.addstr('bold off')
    main_window.attroff(Curses::A_BOLD)
  when 'c'
    # [test begy() and begx()]
    main_window.addstr("begy: #{main_window.begy}, begx: #{main_window.begx}")
  when 'd'
    main_window.clear
    pos.set(1,1)
    main_window.box('|', '-')
  when 'h'
    # Print maxy [test maxy()]
    main_window.addstr("maxy: #{main_window.maxy}")
  when 'q'
    # Print ch [test addch()]
    main_window.addstr('addch(): ')
    main_window.addch('q')
  when 'u'
    # Print string [test addstr()]
    main_window.attrset(Curses::A_BOLD | Curses::A_UNDERLINE)
    main_window.addstr('BOLD AND UNDERLINE')
    main_window.attrset(Curses::A_NORMAL)
  when 'w'
    # Print maxx [test maxx()]
    main_window.addstr("maxx: #{main_window.maxx}")
  when 'x'
    # Kill the Loop
    break
  else
    main_window.attrset(Curses::A_NORMAL)
    main_window.addstr('You did not type A')
  end

  main_window.refresh
end
