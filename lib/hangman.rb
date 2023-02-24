# frozen_string_literal: true

# Initialize various items, check win/loss conditions, save/load games
class Game
  def initialize
    p 'Starting Game....'

    return unless File.exist? 'google-10000-english-no-swears.txt'

    dictionary = File.read('google-10000-english-no-swears.txt')
    wordlist = dictionary.split.delete_if { |word| word.length < 5 || word.length > 12 }
    @secret_word = choose_word(wordlist)
    @player_input = Array.new(@secret_word.length, '_')
  end

  def choose_word(list)
    list[Random.rand(list.length)]
  end

  def check_word(guess)
    if @secret_word.include?(guess)
      indices = []
      @secret_word.each_index { |idx| indices.push[idx] if @secret_word == guess }
      storage(guess, indices)
    else
      p 'You guessed wrong!'
  end

  def storage(guess, locations)
    location.each { |idx| @player_input[idx] = guess }
    win_or_lose
  end

  def win_or_lose
    if @player_input == @secret_word
      p 'You win!'
      endgame('win')
    end
  end
end

# Interacts with the player
class Player
  def initialize
    p 'Player name?'
    @player_name = gets.chomp
    @valid_input = ('a'..'z').to_a
    @game = Game.new
    guesses
  end

  def guesses
    p 'What is your guess?'
    @guess = gets.chomp.downcase
    validate_input(@guess)
    @game.check_word(@guess)
  end

  def validate_input(guess)
    valid = @valid_input.include?(guess)
    if valid
      @valid_input.delete_if { |letter| letter == guess }
      valid
    else
      print "Invalid guess, valid options are #{@valid_input}"
      error('guess')
    end
  end

  def error(code)
    puts "\nWhat is the #{code}?"
    instance_variable_set("@#{code}", gets.chomp.downcase)
    validate_input(@guess)
  end
end
Player.new
