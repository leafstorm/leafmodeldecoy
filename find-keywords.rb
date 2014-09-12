require 'twitter_ebooks'

model = Ebooks::Model.load(ARGV[0])
number = ARGV[1].to_i

model.keywords.top(number).map(&:to_s).map(&:downcase).each do |k|
  puts k
end

