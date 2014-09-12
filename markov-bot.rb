#!/usr/bin/env ruby

require 'twitter_ebooks'

include Ebooks


class MarkovBot
  def self.create(botaccount, model_name, options = {})
    Ebooks::Bot.new(botaccount) do |bot|
      mbot = self.new(bot, model_name, options)
    end
  end

  def initialize(bot, model_name, options = {})
    @bot = bot
    @model = nil
    @model_name = model_name

    @options = options
    bot.oauth_token = options[:oauth_token]
    bot.oauth_token_secret = options[:oauth_token_secret]

    bot.consumer_key = options[:consumer_key]
    bot.consumer_secret = options[:consumer_secret]

    @special_keywords = options[:special_keywords]

    bot.on_startup do
      load_model
      reset_counters
    end

    bot.on_message do |dm|
      delay do
        bot.reply dm, @model.make_response(dm[:text])
      end
    end

    bot.on_follow do |user|
      delay do
        bot.follow user[:screen_name]
      end
    end

    bot.on_mention do |tweet, meta|
      username = tweet[:user][:screen_name]

      # Avoid infinite reply chains
      # There's a 20% chance the bot will just stop talking to another bot,
      # and if that doesn't work we have the rate limit
      next if at_reply_limit?(username)
      next if is_bot?(username) && rand > 0.80

      tokens = NLP.tokenize(tweet[:text])
      bump_reply_count(username)

      if very_interesting?(tokens) || special?(tokens)
        favorite(tweet)
      end

      reply(tweet, meta)
    end

    bot.on_timeline do |tweet, meta|
      username = tweet[:user][:screen_name]

      next if tweet[:retweeted_status] || tweet[:text].start_with?('RT')
      next if @options[:blacklist].include?(username)

      tokens = NLP.tokenize(tweet[:text])

      # We calculate unprompted interaction probability by how well a
      # tweet matches our keywords
      if special?(tokens)
        favorite(tweet)

        delay do
          bot.follow username
        end
      end

      # Any given user will receive at most one random interaction per day
      # (barring special cases)
      next if at_random_limit?(username)

      if very_interesting?(tokens)
        favorite_it = rand < 0.5
        retweet_it = rand < 0.1
        reply_to_it = rand < 0.1
      elsif special?(tokens)
        favorite_it = false       # it's already been favorited!
        retweet_it = rand < 0.1
        reply_to_it = rand < 0.1
      elsif interesting?(tokens)
        favorite_it = rand < 0.1
        reply_to_it = rand < 0.05
        retweet_it = false
      end

      if favorite_it || retweet_it || reply_to_it
        bump_random_count(username)
        favorite(tweet) if favorite_it
        retweet(tweet) if retweet_it
        reply(tweet, meta) if reply_to_it
      end
    end

    # Reload our model
    bot.scheduler.every '3h' do
      `sh update.sh #{model_name}`
      load_model
    end

    bot.scheduler.every '12h' do
      reset_counters
    end

    %w{9 12 15 18 21}.each do |hour|
      bot.scheduler.cron "5 #{hour} * * *" do
        bot.tweet @model.make_statement
      end
    end
  end

  def is_bot?(username)
    username.downcase.include?('ebooks') || username.downcase.include?('bot')
  end

  def interesting?(tokens)
    tokens.find { |t| @top100.include?(t.downcase) }
  end

  def very_interesting?(tokens)
    tokens.find_all { |t| @top20.include?(t.downcase) }.length > 2
  end

  def special?(tokens)
    tokens.find { |t| @special_keywords.include?(t) }
  end

  def load_model
    @model = Model.load("model/#{@model_name}.model")
    @top100 = @model.keywords.top(100).map(&:to_s).map(&:downcase)
    @top20 = @model.keywords.top(20).map(&:to_s).map(&:downcase)
  end

  def reset_counters
    @random_counts = Hash.new 0
    @reply_counts = Hash.new 0
  end

  def at_random_limit?(username)
    @random_counts[username] > 0
  end

  def bump_random_count(username)
    @random_counts[username] += 1
  end

  def at_reply_limit?(username)
    @reply_counts[username] > 20
  end

  def bump_reply_count(username)
    @reply_counts[username] += 1
  end

  def delay(&block)
    @bot.delay @options[:delay], &block
  end

  def reply(tweet, meta)
    resp = @model.make_response(meta[:mentionless], meta[:limit])
    delay do
      @bot.reply tweet, meta[:reply_prefix] + resp
    end
  end

  def favorite(tweet)
    @bot.log "Favoriting @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    delay do
      begin
        @bot.twitter.favorite(tweet[:id])
      rescue Twitter::Error::Forbidden
        @bot.log "Whoops, already favorited that one."
      end
    end
  end

  def retweet(tweet)
    @bot.log "Retweeting @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    delay do
      begin
        @bot.twitter.retweet(tweet[:id])
      rescue Twitter::Error::Forbidden
        @bot.log "Whoops, already retweeted that one."
      end
    end
  end
end

