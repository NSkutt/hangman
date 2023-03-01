# frozen_string_literal: true

require 'yaml'

# Handles valid user input
class Game
  def initialize(save_class)
    p 'Starting Game....'

    return unless File.exist? 'google-10000-english-no-swears.txt'

    dictionary = File.read('google-10000-english-no-swears.txt')
    wordlist = dictionary.split.delete_if { |word| word.length < 5 || word.length > 12 }
    @secret_word = choose_word(wordlist)
    @player_input = Array.new(@secret_word.length, '_')
    @count = 0
    @display = Display.new
    @display.show_player_guess(@player_input, @count)
    @save = save_class
  end

  def choose_word(list)
    list[Random.rand(list.length)]
  end

  def check_word(guess)
    if @secret_word.include?(guess)
      indices = []
      @secret_word.chars.each_index { |idx| indices.push(idx) if @secret_word[idx] == guess }
      storage(guess, indices)
    else
      p 'You guessed wrong!'
      @count += 1
      display
    end
  end

  def storage(guess, locations)
    locations.each { |idx| @player_input[idx] = guess }
    display
  end

  def display
    @display.show_player_guess(@player_input, @count)
    win_or_lose
  end

  def win_or_lose
    if @player_input.join == @secret_word
      game_end('win')
    elsif @count >= 7
      game_end('lose')
    else
      false
    end
  end

  def game_end(w_l)
    p "You #{w_l}! Would you like to try again?"
    true
  end

  def save_data
    @save.save_game(@secret_word, @player_input, @count)
  end
end

# Interacts with the player
class Player
  def initialize
    p 'Player name?'
    @player_name = gets.chomp
    validate_player_name(@player_name)
    @valid_input = ('a'..'z').to_a
    @save = Save.new
    @game = Game.new(@save)
    guesses
  end

  def validate_player_name(name)
    error('player_name') if name[0] !~ /[a-z]/i
  end

  def guesses
    p 'What is your guess?'
    @guess = gets.chomp.downcase
    validate_guess(@guess)
    gameover = @game.check_word(@guess)
    game_finished(gameover)
  end

  def validate_guess(guess)
    return saving if guess.downcase == 'save'

    valid = @valid_input.include?(guess)
    if valid
      @valid_input.delete_if { |letter| letter == guess }
    else
      print "Invalid guess, valid options are #{@valid_input.join(', ')}"
      error('guess')
    end
  end

  def saving
    @save.make_file(@player_name)
    @game.save_data
  end

  def error(code)
    puts "\nWhat is the #{code}?"
    new_input = instance_variable_set("@#{code}", gets.chomp.downcase)
    send("validate_#{code}", new_input)
  end

  def game_finished(gameover)
    if gameover == true
      if gets.chomp.downcase == 'yes'
        Player.new
      else
        exit
      end
    else
      guesses
    end
  end
end

# Shows the players how many turns they have left and how much they have guessed
class Display
  def show_player_guess(current_word, count)
    p current_word.join(' ')
    display_hangman(count)
  end
end

def display_hangman(count)
  temp_store = []
  hangman = [
    "_____\n", "|   |\n",
    ["|  ", ["\\", ["O"], [[["/"]]]], "\n"], ["|   ", [[["|"]]], "\n"],
    ["|  ", [[[[["/"]]]], [[[[[" \\"]]]]]], "\n"], "|____"
  ]
  hangman.flatten(count).each { |layer| temp_store.push(layer) if layer.class != Array }
  puts temp_store.join if count.positive?
end

# Saves Games and Loads previous Saves
class SaveLoad
  def make_file(name)
    while @file_name.nil?

      @file_name = "#{name.downcase}#{Random.rand(10_000_000)}"
      next unless File.exist?("saved/#{@file_name}")

      puts 'Overwrite existing game?'
      if gets.chomp.downcase != 'yes'
        puts 'Did not save'
      else
        puts 'Saving game...'
      end
    end
  end

  def save_game(word, guess_state, guesses_left)

  end

  def load_game

  end
end

Player.new
