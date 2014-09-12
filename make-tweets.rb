require 'twitter_ebooks'

model = Ebooks::Model.load(ARGV[0])
number = ARGV[1].to_i

number.times do
    puts model.make_statement(140)
end

