require 'json'

class WelcomeController < ApplicationController
  
  def index
    @data_transfer = DataTransfer.new
  end

  def viewData
    keyword = params[:data_transfer][:keyword].downcase
    @display = keyword
    keywordDB = Keyword.find_by(word:keyword)
    @count = 0
    @time_array = []
    if keywordDB 
      @count = keywordDB.tweets.count
      start = keywordDB.tweets.first.tTime
      keywordDB.tweets.each do |tweet|
        dif = TimeDifference.between(start,tweet.tTime).in_minutes/15
        if @time_array[dif]
          @time_array[dif] +=1
        else @time_array[dif] = 1
        end
      end
    end
    render 'welcome/viewdata'
  end

  def most_common_word
    #this will be your output array. Please talk with whoever is doing
    # #4 for more details. 
    @word_array = []

    #Basic parameter to make sure post is working
    @keyword = params[:most_common_word][:keyword]

    #This is the passed in keyword you will work with
    keyword = params[:most_common_word][:keyword].downcase
    keywordDB = Keyword.find_by(word:keyword)

    #If the keyword is valid, we will loop through tweets.
    if keywordDB

      #earliest and latest tweet
      @start_time = keywordDB.tweets.first.tTime
      @end_time = keywordDB.tweets.last.tTime

      #no. of time intervals
      interval = 15.minutes
      size = (@end_time - @start_time) / interval + 1

      word_frequency = []
      #array of hashes storing frequencies of all words
      for i in 1..size
        word_frequency.push(Hash.new(0))
      end

      keywordDB.tweets.each do |tweet|

        tweet.tText.delete("\"[]").split(', ').each do |word|
          if word[/[a-zA-Z]+/] == word && word != keyword && !ApplicationHelper::Blacklist.include?(word)
            index = (tweet.tTime - @start_time) / interval
            word_frequency[index][word] += 1
          end

        end
      end
    end

    for i in 0..(size - 1)
      @word_array.push(word_frequency[i].invert.max)
    end
  end

  def stock_analysis
    set_up_company
    set_up_stock
    set_up_stock_prices
    #this will be your output array. Please talk with whoever is doing
    # #4 for more details. 
    @company_tweet_array = []
    @company_header_array = []
    #Basic parameter to make sure post is working
    @keyword = params[:stocks][:keyword]

    #This is the passed in keyword you will work with
    keyword = params[:stocks][:keyword].downcase

    @stock_hourly_price = @@stock_price_hash[keyword]
    if !@stock_hourly_price
      @stock_hourly_price = []
    end

    #first tweet time
    @start = Tweet.find_by(id:1).tTime
    @end = Tweet.last.tTime
    #STOCK DATA
    @stock = StockQuote::Stock.json_quote(@@stock_name_hash[keyword],
      @start,@end).to_json
    #@stock = StockQuote::Stock.quote(@@stock_name_hash[keyword])
    #Visit https://github.com/tyrauber/stock_quote for api

    #If the keyword is valid, we will loop through tweets.
    if (@@company_hash)[keyword]
      company_keywords = (@@company_hash)[keyword]
      company_keywords.each do |keywordC|
        personal_array = []
        keywordDB = Keyword.find_by(word:keywordC)
        @company_header_array<<(keywordC)
        if keywordDB
          keywordDB.tweets.each do |tweet|
            dif = TimeDifference.between(@start,tweet.tTime).in_minutes/15
            if personal_array[dif]
              personal_array[dif] +=1
            else personal_array[dif] = 1
            end
          end
        end
        temporary_array = []

        while personal_array.slice(0,4)!= [] do
          temporary_array
          split = personal_array.slice(0,4)
          addition = split.reduce(0) do |sum,n|
              if n
                sum+n
              else sum
              end
          end
          temporary_array<<addition/split.size.to_f
          personal_array.slice!(0,4)
        end

        @company_tweet_array.push(temporary_array)
      end
    end
    if @company_tweet_array.size > 0
      @max_size = @company_tweet_array.max {|a,b| a.size<=>b.size}.size
    else @max_size = 0
    end
    #you will also need to get stock data somehow and store it for
    #display in the view
  end

  def most_popular
    @word_array = ["Default"]
    @count_array = [1]
    allKeywords = Keyword.all
    allKeywords.each do |keyword|
      if keyword && keyword.word
          @word_array << keyword.word
          @count_array << keyword.tweets.count
      end
    end 
    @count_array,@word_array = @count_array.zip(@word_array)
      .sort.reverse.transpose
    #render 'welcome/mostcommon'
  end

  def getData
    @data_transfer = DataTransfer.new
    k = Keyword.new
    k.save
    k.delay.get_tweets
    #k.destroy
    render 'welcome/index'
  end

  def tweet_over_time
    @time_array = []
    @count = Tweet.all.count
    start = Tweet.find_by(id:1).tTime
    # Tweet.all.each do |tweet|
    #   start = tweet.tTime if start==0
    #   if TimeDifference.between(tweet.tTime,start).in_minutes <0
    #     start = tweet.tTime
    #   end
    # end
    Tweet.all.each do |tweet|
      dif = TimeDifference.between(start,tweet.tTime).in_minutes/15
      if @time_array[dif]
        @time_array[dif] +=1
      else @time_array[dif] = 1
      end
    end
  end
end
