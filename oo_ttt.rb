module Terminal
  def line_space
    puts " "
  end

  def reset_terminal
    system 'clear'
  end
end

module Scorable
  @@computer_score = 0
  @@player_score = 0

  def increase_player_score
    @@player_score += 1
  end

  def increase_computer_score
    @@computer_score += 1
  end

  def player_score
    @@player_score
  end

  def computer_score
    @@computer_score
  end

  def clear_scores
    @@player_score = 0
    @@computer_score = 0
  end

  def display_final_score
    puts "Final score:"
    puts "You : #{player_score}"
    puts "Computer : #{computer_score}"
  end

  def display_current_score
    puts "Current score:"
    puts "You : #{player_score}"
    puts "Computer : #{computer_score}"
  end

  def winning_score?
    @@player_score == 5 || @@computer_score == 5
  end
end

class Board
  include Terminal

  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9], # Horizontal
                   [1, 4, 7], [2, 5, 8], [3, 6, 9], # Vertical
                   [1, 5, 9], [3, 5, 7]] # Diagonal

  def initialize
    @squares = {}
    reset
  end

  def draw_board
    line_space
    draw_squares(1, 2, 3)
    draw_separating_lines
    draw_squares(4, 5, 6)
    draw_separating_lines
    draw_squares(7, 8, 9)
  end

  def draw_squares(a, b, c)
    puts "     |     |"
    puts "  #{@squares[a]}  |  #{@squares[b]}  |  #{@squares[c]}  "
    puts "     |     |"
  end

  def draw_separating_lines
    puts "-----+-----+-----"
  end

  def []=(num, marker)
    @squares[num].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3
    markers.min == markers.max
  end

  def two_identical_markers?(squares, marker_kind)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 2
    markers.all?(marker_kind)
  end

  def middle_square_available?
    @squares[5].marker == Square::INITIAL_MARKER
  end

  def play_middle_square
    @squares[5].marker = TTTGame.computer_marker
  end

  def immediate_threat?
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if two_identical_markers?(squares, TTTGame.human_marker)
        return true
      end
    end
    false
  end

  def computer_defensive_move
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if two_identical_markers?(squares, TTTGame.human_marker)
        squares.each do |square|
          if square.marker == Square::INITIAL_MARKER
            return square.marker = TTTGame.computer_marker
          end
        end
      end
    end
  end

  def possible_winning_move?
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if two_identical_markers?(squares, TTTGame.computer_marker)
        return true
      end
    end
    false
  end

  def computer_winning_move
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if two_identical_markers?(squares, TTTGame.computer_marker)
        squares.each do |square|
          if square.marker == Square::INITIAL_MARKER
            return square.marker = TTTGame.computer_marker
          end
        end
      end
    end
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  def join_or(arr, delimiter = ', ', preposition = ' or ')
    if arr.size == 2
      arr.join(preposition)
    elsif arr.size >= 3
      arr[0..-2].join(delimiter) + preposition + arr.last.to_s
    else
      arr.last.to_s
    end
  end
end

class Square
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  attr_accessor :marker, :name

  def initialize(marker)
    @marker = marker
    @name = nil
  end
end

class TTTGame
  include Terminal
  include Scorable

  @@human_marker = ''
  @@computer_marker = ''
  FIRST_TO_MOVE = 'X'

  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Player.new(@@human_marker)
    @computer = Player.new(@@computer_marker)
    @current_marker = FIRST_TO_MOVE
  end

  def self.human_marker
    @@human_marker
  end

  def self.computer_marker
    @@computer_marker
  end

  private

  def all_spaces?(name)
    name.chars.all? { |let| let == ' ' }
  end

  def set_player_name
    player_name = nil
    puts "Hello there..."
    loop do
      puts "Please enter your name:"
      player_name = gets.chomp.squeeze
      break unless player_name.empty? || all_spaces?(player_name)
      puts "Sorry, you must enter a value:"
    end
    human.name = player_name
    computer.name = %w(R2D2 C3PO BB4 Dr.Evil).sample
  end

  def player_chooses_marker
    answer = nil
    loop do
      puts "Which marker would you prefer to use? (X or O) X moves first"
      answer = gets.chomp
      break if ["X", "O"].include?(answer.upcase)
      puts "Sorry, you must enter X or O..."
    end
    human.marker = answer.upcase
    computer.marker = (human.marker == "X" ? "O" : "X")
    set_markers
  end

  def set_markers
    @@human_marker = human.marker
    @@computer_marker = computer.marker
  end

  def square_validation
    square = gets.chomp
    if square.to_i != square.to_f
      puts "Sorry, please enter whole numbers only..."
    elsif !board.unmarked_keys.include?(square.to_i)
      puts "Sorry, that is not a valid choice..."
    else
      square.to_i
    end
  end

  def human_moves
    puts "Choose an available square (#{board.join_or(board.unmarked_keys)}):"
    square = nil
    loop do
      square = square_validation
      break if board.unmarked_keys.include?(square)
    end
    board.[]=(square, human.marker)
  end

  def computer_moves
    if board.possible_winning_move?
      board.computer_winning_move
    elsif board.immediate_threat?
      board.computer_defensive_move
    elsif board.middle_square_available?
      board.play_middle_square
    else
      computer_random_move
    end
  end

  def computer_random_move
    board.[]=(board.unmarked_keys.sample, computer.marker)
  end

  def current_player_moves
    if human_turn?
      human_moves
      @current_marker = @@computer_marker
    else
      computer_moves
      @current_marker = @@human_marker
    end
  end

  def human_turn?
    @current_marker == @@human_marker
  end

  def display_board
    reset_terminal
    puts "You're #{human.marker}"
    puts "Computer is #{computer.marker}"
    board.draw_board
  end

  def clear_and_display_board
    reset_terminal
    display_board
  end

  def display_welcome_and_rules_message
    reset_terminal
    puts "Welcome to Tic Tac Toe #{human.name}!"
    line_space
    puts "You will be facing #{computer.name} today!"
    line_space
    rules_to_win_message
    player_chooses_marker
  end

  def rules_to_win_message
    line_space
    puts "The first player to win 5 rounds wins the game..."
    line_space
    puts "Good luck!"
    line_space
  end

  def display_goodbye_message
    reset_terminal
    puts "Thanks for playing Tic Tac Toe #{human.name}!"
    line_space
    puts "Have a wonderful day!"
  end

  def result
    if board.winning_marker == human.marker
      puts "You won!"
      increase_player_score
    elsif board.winning_marker == computer.marker
      puts "Computer won!"
      increase_computer_score
    else
      puts "It's a tie!"
    end
  end

  def display_result
    clear_and_display_board
    result
    display_current_score
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if %w(y n).include?(answer)
      puts "Sorry, must be y or n"
    end
    clear_scores
    answer == 'y'
  end

  def game_reset
    board.reset
    @current_marker = FIRST_TO_MOVE
    reset_terminal
  end

  def display_play_again_message
    puts "Let's play again!"
    line_space
    player_chooses_marker
  end

  def player_move
    loop do
      current_player_moves
      break if board.full? || board.someone_won?
      clear_and_display_board if human_turn?
    end
  end

  def board_display_player_moves
    display_board
    player_move
  end

  def main_game
    loop do
      board_display_player_moves
      display_result
      sleep(1)
      game_reset
      if winning_score?
        break unless play_again?
        display_play_again_message
      end
    end
  end

  public

  def play
    reset_terminal
    set_player_name
    display_welcome_and_rules_message
    main_game
    display_goodbye_message
  end
end

game = TTTGame.new
game.play
