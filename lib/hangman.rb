# frozen_string_literal: true

require 'yaml'

# Handles valid user input
class Game
  def initialize(save_class, data = nil)
    return unless File.exist? 'google-10000-english-no-swears.txt'

    p 'Starting Game....'
    @save = save_class

    data.nil? ? set_variables : load_data(data)

    @display = Display.new
    @display.show_player_guess(@player_input, @count)
  end

  def set_variables
    dictionary = File.read('google-10000-english-no-swears.txt')
    wordlist = dictionary.split.delete_if { |word| word.length < 5 || word.length > 12 }
    @secret_word = choose_word(wordlist)
    @player_input = Array.new(@secret_word.length, '_')
    @count = 0
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
    p "You #{w_l}! Would you like to try again? (yes/no)"
    @save.delete_file unless @save.load.nil?
    true
  end

  def save_data(valid_input)
    @save.save_game(@secret_word, @player_input, @count, valid_input)
  end

  def load_data(data)
    @secret_word = data[:word]
    @player_input = data[:guess_state]
    @count = data[:guesses_left]
  end
end

# Interacts with the player
class Player
  def initialize
    @save = SaveLoad.new
    p 'Would you like to load a previous game? (yes/no)'
    ans = gets.chomp
    data = loading if ans.downcase == 'yes'
    @save.load.nil? ? new_game : load(data)

    guesses
  end

  def new_game
    p 'Player name?'
    @player_name = gets.chomp
    validate_player_name(@player_name)
    @valid_input = ('a'..'z').to_a
    @game = Game.new(@save)
  end

  def loading
    puts 'What is the file name?'
    file = gets.chomp
    @save.load_game(file)
  end

  def load(data)
    @player_name = data[:player_name]
    @valid_input = data[:options]
    @game = Game.new(@save, data)
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
    @save.verify_file(@player_name)
    @game.save_data(@valid_input)
    exit
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
  ] # Using single quotes does not work in this array, even when it would be seemingly valid
  hangman.flatten(count).each { |layer| temp_store.push(layer) if layer.class != Array }
  puts temp_store.join if count.positive?
end

# Saves Games and Loads previous Saves
class SaveLoad
  attr_reader :load

  def verify_file(name)
    @name = name
    Dir.mkdir('saves') unless Dir.exist?('saves')
    make_file(name) if @file_name.nil?
  end

  def make_file(name)
    @file_name = "saves/#{name.downcase}#{Random.rand(10_000_000)}.yaml"
    return unless File.exist?(@file_name)

    puts 'Overwrite existing game? (yes/no)'
    if gets.chomp.downcase != 'yes'
      puts 'Did not save'
    else
      puts 'Saving game...'
    end
  end

  def save_game(word, guess_state, guesses_left, options)
    data = {
      player_name: @name,
      word: word,
      guess_state: guess_state,
      guesses_left: guesses_left,
      options: options
    }
    File.open(@file_name, 'w') { |file| file.puts YAML.dump(data) }
  end

  def load_game(file_name)
    @load = true
    @file_name = file_name.rstrip
    @file_name.prepend('saves/') if @file_name[0, 6] != 'saves/'
    yaml_file = File.open(@file_name)
    ruby_data = YAML.load(yaml_file)
    yaml_file.close
    ruby_data
  end

  def delete_file
    File.delete(@file_name) if File.exist? @file_name
  end
end

Player.new
