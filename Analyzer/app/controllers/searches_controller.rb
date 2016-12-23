class SearchesController < ApplicationController
  dictionary = Dictionary.from_file('en copy.txt')
  def index
    @searches = Search.all
  end

  def new
    @search = Search.new
  end

  def create
    @search = Search.new(search_params)
    #redirect_to @search if it's here it goes to index
    if @search.save
      redirect_to @search #here it goes to show.html.erb
      @query = @search.entry
      gon.entry = @query
    else
      render 'new'
    end
  end

  def destroy
    @search = Search.find(params[:id])
    @search.destroy

    redirect_to searches_path
  end

  def words

  end

  def show
    #dictionary for checking spelling errors
    dictionary = Dictionary.from_file('en copy.txt')

    @search = Search.find(params[:id])

    client = Twitter::REST::Client.new do |config|
      config.consumer_key = 	"PIcmOUhhiokFoVV2MKcTf5zq7"
      config.consumer_secret = "byrAw52h8yQB0wpmtHhYEYfhUsLT0ifs7JHJfcwccEDT2pCHur"
      config.access_token = "750506018744832000-rLtS7VCeOW59PSGpn5F27zNubaYj153"
      config.access_token_secret = "JbMM8fDX4fO6Izw0vKCCAO26ygHuKfQoPRiAdLyEF8yG1"
    end

    #instantiate the hash to track top word usage_count_array
    @top_words = Hash.new(0)
    #the string we will add all words to
    super_long_string = ""
    #start the error count at 0
    @error_count = 0
    #grab the first 200 tweets (make the amount changeable)
    @tweets = client.user_timeline("@" + @search.entry, count: 200, include_rts: false)

    #this is an array for all the misspelled words
    $misspelled_words = []
    #the hash for times when they tweet
    $tweet_time_preference = {
      :super_early_morning => 0,
      :morning => 0,
      :afternoon => 0,
      :evening => 0,
      :night => 0,
      :late_night => 0
    }
    #the total number of words
    $total_word_count = 0

    #the array consisting of an array of arrays of arrays
    #the first element is an array of 4 arrays (the four coordinates pairs)
    #each element of this inner array is a coordinate pair - 4 in total
    @locations = []
    @tweets.each do |tweet|
      #get the tweet created at time and convert it to PACIFIC time (for now)
      tweet_time = tweet.created_at.in_time_zone('America/Los_Angeles').strftime("%H").to_i
      #this gets all the info about the tweet
      tweet_attributes = tweet.attrs
      #gets the coordinates of the tweet (if it exists)
      location = tweet_attributes.dig(:place, :bounding_box, :coordinates)
      #if the location DOES exist
      if location != nil
        #add the array of 4 coordinate pairs to the locations array
        @locations.push(location[0])
      end

      #if the time is between 4 and 6 am
      if (tweet_time >= 4 && tweet_time <= 6)
        $tweet_time_preference[:super_early_morning] += 1
      #time is between 7 and 11am
      elsif (tweet_time >= 7 && tweet_time <= 11)
        $tweet_time_preference[:morning] += 1
      #time is bettwen noon and 4 pm
      elsif (tweet_time >= 12 && tweet_time <= 16)
        $tweet_time_preference[:afternoon] += 1
      #time is between 5 and 7pm
      elsif (tweet_time >= 17 && tweet_time <= 19)
        $tweet_time_preference[:evening] += 1
      #time is between 8 and midnight
      elsif (tweet_time >= 20 && tweet_time <= 24)
        $tweet_time_preference[:night] += 1
      else
        #time is between 1 am and 3 am
        $tweet_time_preference[:late_night] += 1
      end
      #@tweet_time_preference = @tweet_time_preference.sort_by {|k,v| v}.reverse
      gon.tweet_times = $tweet_time_preference

      #pass the locations array to the js file (array of arrays of arrays)
      gon.locations = @locations
      text = clean_tweet(tweet.text) #get the text of each tweet and remove emojis/hashtags etc
      words = text.split(" ") #splits tweet into an array of words
      words.each do |word|
        #keep track of how many total words there were
        $total_word_count += 1
        #convert the word to a symbol
        word_to_add = word.to_sym
        #make the word the key and increment its value by 1
        @top_words[word_to_add] += 1
        if (not dictionary.exists?(word)) && #not in dictionary and not an image
          (not single_letter_checker(word)) && #not 'a' or 'A' and not a hashtag
          (not integer_checker(word)) #not a number
          $misspelled_words.push(word) #add it to the misspelled words array
          @error_count += 1 #increment the count of wrong words
        end
      end
      @score = $total_word_count
    end
    #pass the misspelled words array to js
    gon.misspelled_words = $misspelled_words
    gon.total = $total_word_count

    #a counter to reach 10 in the top words hash
    word_count = 1
    #an array of the top words that will be passed to the view
    @top_words_array = []
    #sort the hash by value in descending order
    @top_words = @top_words.sort_by {|k,v| v}.reverse
    @top_words.each do |word, count|
      top_word = Array.new(2)
      if word_count < 11
        #set the top_word array's elements to word and it's count
        top_word[0] = word
        top_word[1] = count
        #push the word and count tot he top_words_array
        @top_words_array.push(top_word)
        #increment the counter
        word_count += 1
      end
    end
    gon.top_words = @top_words_array
  end

  ##################### DICTIONARY/FILTERING TWEETS METHODS ############################
  def remove_emojis(word)
    regex = /[\u{203C}\u{2049}\u{20E3}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{23E9}-\u{23EC}\u{23F0}\u{23F3}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2600}-\u{2601}\u{260E}\u{2611}\u{2614}-\u{2615}\u{261D}\u{263A}\u{2648}-\u{2653}\u{2660}\u{2663}\u{2665}-\u{2666}\u{2668}\u{267B}\u{267F}\u{2693}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26CE}\u{26D4}\u{26EA}\u{26F2}-\u{26F3}\u{26F5}\u{26FA}\u{26FD}\u{2702}\u{2705}\u{2708}-\u{270C}\u{270F}\u{2712}\u{2714}\u{2716}\u{2728}\u{2733}-\u{2734}\u{2744}\u{2747}\u{274C}\u{274E}\u{2753}-\u{2755}\u{2757}\u{2764}\u{2795}-\u{2797}\u{27A1}\u{27B0}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B50}\u{2B55}\u{3030}\u{303D}\u{3297}\u{3299}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{1F191}-\u{1F19A}\u{1F1E7}-\u{1F1EC}\u{1F1EE}-\u{1F1F0}\u{1F1F3}\u{1F1F5}\u{1F1F7}-\u{1F1FA}\u{1F201}-\u{1F202}\u{1F21A}\u{1F22F}\u{1F232}-\u{1F23A}\u{1F250}-\u{1F251}\u{1F300}-\u{1F320}\u{1F330}-\u{1F335}\u{1F337}-\u{1F37C}\u{1F380}-\u{1F393}\u{1F3A0}-\u{1F3C4}\u{1F3C6}-\u{1F3CA}\u{1F3E0}-\u{1F3F0}\u{1F400}-\u{1F43E}\u{1F440}\u{1F442}-\u{1F4F7}\u{1F4F9}-\u{1F4FC}\u{1F500}-\u{1F507}\u{1F509}-\u{1F53D}\u{1F550}-\u{1F567}\u{1F5FB}-\u{1F640}\u{1F645}-\u{1F64F}\u{1F680}-\u{1F68A}]/
    return word.gsub regex, ' '
  end

  def hashtag_checker(word) #check if the word is a hashtag
    if word.split("")[0] == "#"
      return true
    else
      return false
    end
  end

  def integer_checker(word) #check if this is a number
    return word =~ /\A\d+\z/ ? true : false
  end

  def has_apostrophe?(word)
    letters = word.split("")
    word_length = letters.count
    second_to_last_letter = letters[word_length - 2]
    if second_to_last_letter == "'"
      return true
    else
      return false
    end
  end

  def retweet_check(tweet) #you should pass in the actual tweet
    words = tweet.split(" ")
    if words[0] == "RT"
      return true
    else
      return false
    end
  end

  def single_letter_checker(word)
    acceptable = ['a', 'I']
    if acceptable.include? word
      return true
    else
      return false
    end
  end

  def mention_check(word) #you should pass in only one word at at time
    letters = word.split("") #this is an array of letters now
    if letters.include? '@'
      return true
    else
      return false
    end
  end

  def image_checker(word)
    if word.include? "https://"
      return true
    else
      return false
    end
  end

  def website_checker(word)
    if word.include? "http://"
      return true
    else
      return false
    end
  end

  def possesive_noun?(word)
    letters = word.split("")
    length_of_word = letters.count
    last_letter = letters[length_of_word - 1]
    second_to_last_letter = letters[length_of_word - 2]
    if last_letter == "s"
      if second_to_last_letter == "'"
        return true
      end
    end
    return false
  end

  def is_contraction?(word) #pass in single words
    contractions = ["aren't", "can't", "could've", "couldn't",
    "didn't", "doesn't", "don't", "hadn't", "hasn't", "haven't", "he'd",
    "he'll", "he's", "how'd", "how's",
    "isn't", "it'd", "it'll", "it's", "let's", "she'd", "she'll", "she's",
    "should've", "shouldn't", "that'll", "that's", "there'd", "there's",
    "they'd", "they'll", "they're", "wasn't", "we'd", "we'll", "we're",
    "we've", "weren't", "what'll", "what's", "what've", "when's", "where'd",
    "where's", "who'd", "who'll", "who's", "won't", "would've", "wouldn't", "you'd",
    "you'll", "you're", "you've"]
    if contractions.include? word
      return true
    else
      return false
    end
  end

  def contains_I?(word)
    acceptable = ["I'd", "I'll", "I'm", "I've"]
    if acceptable.include? word
      return true
    else
      return false
    end
  end

  def is_a_name?(word)
    names = [
      "James", "John", "Robert", "Michael", "William", "David", "Richard",
      "Joseph", "Thomas", "Charles", "Charlie", "Christopher", "Daniel",
      "Matthew", "Anthony", "Donald", "Mark", "Mary", "Patricia", "Jennifer",
      "Elizabeth", "Linda", "Barbara", "Susan", "Jessica", "Jessie", "Margaret",
      "Sarah", "Karen", "Nancy", "Betty", "Dorothy", "Lisa", "Sandra",
      "Paul", "Steven", "George", "Kenneth", "Ken", "Andrew", "Joshua",
      "Edward", "Brian", "Kevin", "Ronald", "Bryan", "Bryant", "Alan", "Timothy",
      "Tim", "Jason", "Jeffrey", "Ryan", "Gary", "Jacob", "Nicholas", "Nick", "Eric",
      "Stephen", "Jonathan", "Ashley", "Kim", "Kimberly", "Donna", "Carol",
      "Michelle", "Emily", "Helen", "Amanda", "Melissa", "Deborah", "Stephanie",
      "Steph", "Laura", "Rebecca", "Becca", "Sharon", "Cynthia", "Kathleen", "Shirley",
      "Amy", "Anna", "Angela", "Larry", "Scott", "Frank", "Justin", "Brandon",
      "Raymond", "Greg", "Gregory", "Sam", "Samuel", "Ben", "Benjamin", "Patrick",
      "Jack", "Alex", "Alexander", "Dennis", "Jerry", "Tyler", "Aaron", "Henry",
      "Douglas", "Peter", "Jose", "Ruth", "Brenda", "Pam", "Pamela", "Virginia",
      "Katherine", "Catherine", "Nicole", "Christine", "Chris", "Samantha",
      "Debra", "Janet", "Carolyn", "Rachel", "Heather", "Maria", "Diane",
      "Emma", "Julie", "Joyce", "Frances", "Adam", "Zachary", "Walter", "Nathan",
      "Harold", "Kyle", "Carl", "Arthur", "Gerald", "Roger", "Keith", "Jeremy",
      "Lawrence", "Larry", "Terry", "Sean", "Shawn", "Albert", "Joe", "Christian",
      "Austin", "Willie", "Evelyn", "Joan", "Christina", "Kelly", "Martha",
      "Lauren", "Victoria", "Judith", "Cheryl", "Megan", "Alice", "Ann", "Jean",
      "Doris", "Andrea", "Marie", "Kathryn", "Jacqueline", "Jackie", "Gloria",
      "Theresa", "Jesse", "Ethan", "Billy", "Bruce", "Bryan", "Ralph", "Roy",
      "Jordan", "Eugene", "Wayne", "Louis", "Dylan", "Juan", "Noah", "Russell",
      "Harry", "Randy", "Philip", "Vincent", "Hannah", "Sara", "Janice", "Julia",
      "Olivia", "Grace", "Rose", "Rosanne", "Theresa", "Judy", "Beverly", "Denise",
      "Marilyn", "Amber", "Danielle", "Danny", "Brittany", "Madison", "Maddie",
      "Diana", "Madeleine", "Alexis", "Jane", "Lori", "Mildred", "Gabriel", "Gabe",
      "Bobby", "Johnny", "Howard", "Tiff", "Tiffany", "Natalie", "Abigail", "Kathy",
      "Jay", "Noah", "Dan", "Josh", "Connor", "Britney", "Whitney", "Kristine", "April",
      "May", "Jenny", "Kelvin"
    ]
    if names.include? word
      return true
    else
      return false
    end
  end

  def quotation_checker(word)
    letters = word.split("")
    length_of_word = letters.count - 1
    if letters[0] == "'" || letters[0] == '"'
      word = word[1..length_of_word]
    end
    return word
  end

  def clean_tweet(tweet) #pass in a tweet and refine it: remove emojis, get rid of non letters
    tweet_text = remove_emojis(tweet) #removes emojis
    words = tweet_text.split(" ") #splits into an array of words
    if words.count == 1
      if (image_checker(words[0])) || (mention_check(words[0]))
        return ""
      end
      word = words[0]
      return word
    else
      words.each do |word| #iterate thru each word
        if (contains_I?(word)) #return true for contractions with "I"
            tweet_text.gsub!(word, "") #remove word from tweet
        end
        if possesive_noun?(word)
          letters = word.split("")
          word_length = letters.count
          refined_word = word[0..word_length - 3]
          tweet_text.gsub!(word, refined_word)
          word = refined_word
        end
        new_word = quotation_checker(word) #remove quotations around words
        tweet_text.gsub!(word, new_word) #refine the tweet
        if (hashtag_checker(new_word)) || (is_a_name?(new_word)) ||
          (mention_check(new_word)) || (image_checker(new_word)) ||
          (is_contraction?(new_word.downcase)) || (website_checker(new_word))
          tweet_text.gsub!(new_word, "")
        end
        if has_apostrophe?(new_word)
          if (not is_contraction?(new_word)) && (not possesive_noun?(new_word)) && (not contains_I?(new_word))
            tweet_text.gsub!(new_word, "")
          end
        end
      end
      tweet_text = tweet_text.replace(tweet_text.gsub!(/\W+/, ' ')) #get rid of all non letter characters
      return tweet_text
    end
  end

  private
    def search_params
      params.require(:search).permit(:entry)
    end
end
