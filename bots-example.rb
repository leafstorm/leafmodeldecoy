#!/usr/bin/env ruby

require_relative 'markov-bot'

MarkovBot.create "LeafModelDecoy", "LeafStorm", {
  :oauth_token        => "",
  :oauth_token_secret => "",
  :consumer_key       => "",
  :consumer_secret    => "",

  :blacklist          => %w{ },

  :delay              => 2..30,
  :special_keywords   => %w{ @leafstorm }
}

