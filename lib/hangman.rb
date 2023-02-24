# frozen_string_literal: true

# Initialize various items, check win/loss conditions, save/load games
class Game
  def initialize
    p 'Starting Game....'

    return unless File.exist? 'google-10000-english-no-swears.txt'

    dictionary = File.read('google-10000-english-no-swears.txt')
    wordlist = dictionary.split.delete_if { |word| word.length < 5 || word.length > 12 }
    @secret_word = choose_word(wordlist)
  end

  def choose_word(list)
    list[Random.rand(list.length)]
  end

  def check_word(guess)
    p "#{@secret_word} : #{guess}"
    p @secret_word.include?(guess)
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
    puts "\nWhat is your guess?"
    guess = gets.chomp.downcase
    puts guess
    @game.check_word(guess) if validate_input(guess)
  end

  def validate_input(guess)
    valid = @valid_input.include?(guess)
    if valid
      @valid_input.delete_if { |letter| letter == guess }
      valid
    else
      print "Invalid guess, valid options are #{@valid_input}"
      guesses
    end
  end
end
Player.new
