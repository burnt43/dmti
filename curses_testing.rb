require 'initialize'

Curses.init_screen
Curses.start_color
Curses.use_default_colors
Curses.raw
Curses.noecho

Curses.init_color(100, 1000, 0, 0)
Curses.init_pair(50, Curses::COLOR_BLACK, Curses::COLOR_RED)
Curses.init_pair(51, Curses::COLOR_GREEN, Curses::COLOR_GREEN)

main_window = Curses.stdscr
pad = Curses::Pad.new(10, 30)
pad.keypad(true)
pad.scrollok(false)

pad_y = 0

pad << "This is the same sentence repeated over and over. " * 6
pad.refresh(pad_y,0, 10,10, main_window.maxy,main_window.maxx)

loop do
  ch = pad.getch
  case ch
  when 'j'
    pad.refresh(pad_y += 1,0, 10,10, main_window.maxy,main_window.maxx)
  when 'k'
    pad.refresh(pad_y -= 1,0, 10,10, main_window.maxy,main_window.maxx)
  when Curses::Key::F1
    break
  end
end


# main_window.keypad(true)
# main_window.box(0, 0)
# main_window.setpos(1,1)
# main_window.refresh



=begin
sub_window = main_window.derwin(
  main_window.maxy - 2,
  main_window.maxx - 2,
  1, 1
)
sub_window.refresh

items = [
  Curses::Item.new('Item 01', ''),
  Curses::Item.new('Item 02', ''),
  Curses::Item.new('Item 03', '')
]
menu = Curses::Menu.new(items)

menu_window = sub_window.derwin(20, 40, 1, 1)
menu_window.box(0, 0)
menu_container = menu_window.derwin(18, 38, 1, 1)

menu.set_win(menu_window)
menu.set_sub(menu_container)

menu_window.refresh
menu_container.refresh

menu.post

form_window = sub_window.derwin(20, 40, 1, 50)
form_window.box(0, 0)

form_container = form_window.derwin(18, 38, 1, 1)

fields = [
  Curses::Field.new(1, 20, 0, 0, 0, 1),
  Curses::Field.new(1, 20, 1, 0, 0, 1),
]
fields.each do |f|
  f.back = (50 << 8) | Curses::A_UNDERLINE
  f.fore = (50 << 8) | Curses::A_UNDERLINE
  f.set_buffer(0, "#{f.buffer(0)} #{f.buffer(0).class.name}")
end
form = Curses::Form.new(fields)
form.set_win(form_window)
form.set_sub(form_container)

form_window.refresh
form_container.refresh

form.post

form.driver('T')
form.driver('e')
form.driver(Curses::REQ_NEXT_FIELD)
form.driver('s')
form.driver('t')

# form.driver(Curses::REQ_NEXT_FIELD)
# sleep 1
# form.driver(Curses::REQ_PREV_FIELD)

loop do
  ch = main_window.getch

  case ch
  when 'x'
    menu.unpost
  when 'c'
    menu.post
  when 'k'
    if menu.current_item != items[0]
      menu.up_item
    end
  when 'j'
    if menu.current_item != items[-1]
      menu.down_item
    end
  when Curses::Key::F1
    break
  end

  # case ch
  # when 'a'
  #   main_window.insch('z')
  #   main_window.insch('y')
  # when 'b'
  #   main_window.insertln
  # when 'c'
  #   main_window.setpos(10,1)
  #   main_window << "string"
  #   main_window << "#{main_window.line_touched?(10)}"
  # when 'd'
  #   new_window = main_window.derwin(20,20,5,5)
  #   new_window.box(0, 0)
  #   new_window.refresh
  #   sleep 1
  #   new_window.erase
  #   new_window.refresh
  #   new_window.move(5,10)
  #   new_window.box(0, 0)
  #   new_window.refresh
  #   sleep 1
  #   new_window.resize(25,25)
  #   new_window.erase
  #   new_window.box(0, 0)
  #   new_window.refresh
  # when 'e'
  #   sub_window.scrollok(true)
  #   lines = sub_window.maxy + 20
  #   max_line = sub_window.maxy - 1

  #   (0..lines).each do |y|
  #     if y > max_line
  #       sub_window.scroll
  #       sub_window.setpos(max_line, 0)
  #     else
  #       sub_window.setpos(y, 0)
  #     end

  #     sub_window << "Line ##{y}"
  #     sub_window.refresh

  #     sleep 0.05
  #   end
  # when Curses::Key::F1
  #   break
  # end
end

=end

=begin
class StatsWindow
  def initialize
    main_window = Curses.stdscr

    y_dimension = main_window.maxy
    x_dimension = main_window.maxx / 2

    x_pos = x_dimension
    y_pos = 0

    @window = Curses::Window.new(y_dimension, x_dimension, y_pos, x_pos)
    @window.keypad(true)
    @window.box(0, 0)
    @boxed = true
  end

  def refresh
    @window.refresh
  end

  def write_stats(some_window)
    %i[
      y_pos
      x_pos
      effective_miny
      effective_minx
      effective_maxy
      effective_maxx
      at_top_edge?
      at_bottom_edge?
      at_left_edge?
      at_right_edge?
      bkgdch
      highlighted_ch
    ].each_with_index do |method_name, index|
      @window.setpos(index+1,1)
      @window.addstr(' ' * 40)
      @window.setpos(index+1,1)
      @window.addstr(sprintf("%-20s: %s", method_name.to_s, some_window.send(method_name).to_s))
    end
    
    refresh
  end
end

class CursorMovingWindow
  class << self
    def refresh_o_tize_method(method_name)
      new_method_name = "#{method_name}!"
      define_method new_method_name do |*args|
        send(method_name, *args)
        refresh
      end
    end
  end

  def initialize(stats_window)
    main_window = Curses.stdscr

    y_dimension = main_window.maxy
    x_dimension = main_window.maxx / 2

    @window = Curses::Window.new(y_dimension, x_dimension, 0, 0)
    @window.keypad(true)
    @window.box(0, 0)
    @boxed = true

    @stats_window = stats_window

    activate_normal_mode

    setpos(y: 1, x: 1)
  end

  def run_input_loop
    loop do
      ch = @window.getch

      case @mode
      when :insert
        case ch
        when 'a'..'z'
          addch!(ch)
        when Curses::Key::F1
          break
        when Curses::Key::F2
          activate_normal_mode!
        end
      when :normal
        case ch
        when 'd'
          @window.deleteln
          refresh
        when 'e'
          @window.erase
        when 'h'
          dec_x!
        when 'i'
          activate_insert_mode!
        when 'j'
          inc_y!
        when 'k'
          dec_y!
        when 'l'
          inc_x!
        when 'm'
          @window.move(10,0)
          refresh
        when 'r'
          @window.resize(30, 10)
          @window.refresh
        when 'x'
          delch!
        when 'w'
          subwin = @window.derwin(10,10,10,10)
          subwin.box(0, 0)
          subwin.refresh
        when Curses::Key::F1
          break
        end
      end
    end
  end

  def refresh
    @stats_window.write_stats(self)
    @window.refresh
  end

  private

  def y_pos
    @window.cury
  end

  def x_pos
    @window.curx
  end

  def bkgdch
    @window.getbkgd
  end

  def highlighted_ch
    @window.inch
  end

  def nlcr
    if at_bottom_edge?
      false
    else
      setpos(y: y_pos + 1, x: effective_minx)
    end
  end

  def addch(ch)
    if at_right_edge?
      @window.addch(ch)

      if !at_bottom_edge?
        nlcr
      else
        setposrel(x: -1)
      end
    else
      @window.addch(ch)
    end
  end
  refresh_o_tize_method :addch

  def delch
    @window.delch
  end
  refresh_o_tize_method :delch

  def at_top_edge?
    y_pos <= effective_miny
  end

  def at_bottom_edge?
    y_pos >= effective_maxy
  end

  def at_left_edge?
    x_pos <= effective_minx
  end

  def at_right_edge?
    x_pos >= effective_maxx
  end

  def activate_normal_mode
    @mode = :normal
    set_title('Normal Mode')
  end
  refresh_o_tize_method :activate_normal_mode

  def activate_insert_mode
    @mode = :insert
    set_title('Insert Mode')
  end
  refresh_o_tize_method :activate_insert_mode

  def tmp_setpos(new_y, new_x, &block)
    old_y = y_pos
    old_x = x_pos

    setpos(y: new_y, x: new_x)
    block.call
    setpos(y: old_y, x: old_x)
  end

  def setposrel(y: 0, x: 0)
    potential_new_y = y_pos + y
    potential_new_x = x_pos + x

    options = {}.tap do |h|
      if (effective_miny..effective_maxy).include?(potential_new_y)
        h[:y] = potential_new_y
      end

      if (effective_minx..effective_maxx).include?(potential_new_x)
        h[:x] = potential_new_x
      end
    end

    setpos(**options)
  end

  def setpos(y: nil, x: nil)
    new_y = y || y_pos
    new_x = x || x_pos

    @window.setpos(new_y, new_x)
  end

  def set_title(title_string)
    tmp_setpos(0, 1) do
      white_space = ' ' * (title_width - title_string.size)
      @window.attron(Curses::A_STANDOUT)
      @window.addstr(title_string + white_space)
      @window.attroff(Curses::A_STANDOUT)
    end
  end
  refresh_o_tize_method :set_title

  def title_width
    boxed? ? @window.maxx - 2 : @window.maxx
  end

  def boxed?
    @boxed
  end

  def effective_miny
    boxed? ? 1 : 0
  end

  def effective_minx
    boxed? ? 1 : 0
  end

  def effective_maxy
    boxed? ? @window.maxy - 2 : @window.maxy
  end

  def effective_maxx
    boxed? ? @window.maxx - 2 : @window.maxx
  end

  def inc_y
    return if at_bottom_edge?

    setposrel(y: 1)
  end
  refresh_o_tize_method :inc_y

  def inc_x
    return if at_right_edge?

    setposrel(x: 1)
  end
  refresh_o_tize_method :inc_x

  def dec_y
    return if at_top_edge?
    
    setposrel(y: -1)
  end
  refresh_o_tize_method :dec_y

  def dec_x
    return if at_left_edge?
    
    setposrel(x: -1)
  end
  refresh_o_tize_method :dec_x
end

stats = StatsWindow.new
stats.refresh

win = CursorMovingWindow.new(stats)
win.refresh
win.run_input_loop
=end

=begin
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

module Curses
  class Window
    def init_bg(ch = nil)
      ch_for_bg = ch || (getbkgd || 32).chr
      bkgd(ch_for_bg.ord)

      (0..(maxy-1)).each do |y_pos|
        setpos(y_pos, 0)
        addstr(ch_for_bg * (maxx - 0))
      end
    end
  end
end


# start curses mode
Curses.init_screen
Curses.start_color
Curses.use_default_colors

# Curses.init_color(100, 100, 100, 500)
# Curses.init_pair(1, Curses::COLOR_RED, Curses::COLOR_WHITE)
# Curses.init_pair(2, Curses::COLOR_GREEN, 100)

# take all input
Curses.raw

# don't print out what is typed
Curses.noecho

# set window as the top level window
main_window = Curses.stdscr

# be able to capture arrow keys
main_window.keypad(true)

# refresh so the screen draws
main_window.refresh

left_window = Curses::Window.new(main_window.maxy, main_window.maxx / 2, 0, 0)
left_window.keypad(true)
# left_window.color_set(1)
left_window.init_bg
left_window.box(0,0)
left_window.setpos(0,1)
left_window.attron(Curses::A_STANDOUT)
left_window.addstr('Title' + (' ' * (left_window.maxx - 5 - 2)))
left_window.attroff(Curses::A_STANDOUT)

right_window = Curses::Window.new(main_window.maxy, main_window.maxx / 2, 0, main_window.maxx / 2 + 0)
right_window.color_set(2)
right_window.init_bg
right_window.box(0,0)

left_window_y_pos = 0
right_window_y_pos = 0


left_window_y_pos += 1
left_window.setpos(left_window_y_pos, 1)
left_window << "Left Window: (#{left_window.begy}, #{left_window.begx})"

right_window_y_pos += 1
right_window.setpos(right_window_y_pos, 1)
right_window << "Right Window: (#{right_window.begy}, #{right_window.begx})"

left_window_y_pos += 1
left_window.setpos(left_window_y_pos, 1)
left_window.addch('a')

left_window_y_pos += 1
left_window.setpos(left_window_y_pos,1)
left_window.addstr('bc')

left_window_y_pos += 1
left_window.setpos(left_window_y_pos,1)

valid_consts = Set.new(%w[
  A_BLINK
  A_BOLD
  A_DIM
  A_INVIS
  A_NORMAL
  A_PROTECT
  A_STANDOUT
  A_UNDERLINE
])
Curses.constants.map(&:to_s).select {|c| c.start_with?('A_')}.sort.each do |c|
  attr_const = Curses.const_get(c)
  apply_attr = valid_consts.member?(c)

  right_window_y_pos += 1
  right_window.setpos(right_window_y_pos,1)
  right_window.attron(attr_const) if apply_attr
  right_window.addstr(c.to_s)
  right_window.attroff(attr_const) if apply_attr
end

right_window.refresh
left_window.refresh

loop do
  ch = left_window.getch
  case ch
  when 'a'
    right_window.clear
    right_window.refresh
    right_window.close
  when 'b'
    left_window.setpos(1,0)
    left_window.clrtoeol
  when Curses::Key::F1
    break
  when 'x'
    break
  when 'y'
    left_window.addstr(Curses::KEY_F1.to_s)
  else
    left_window.addstr("#{ch}(#{ch.class.name})")
    left_window.addch(' ')
  end
end
=end

=begin
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
=end
