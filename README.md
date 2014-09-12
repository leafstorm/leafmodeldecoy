LeafModelDecoy
==============
This is the backing code for LeafModelDecoy, the Twitter bot that
pretends (badly) to be me. You can use this to make your own imitating
Twitter bots!

It's based heavily on Jaiden Mispy's twitter_ebooks library, from
https://github.com/mispy/twitter_ebooks, and the example he originally
wrote, from https://github.com/mispy/ebooks_example.

This version is much chattier, easier to customize, and includes
some extra safeguards and behaviors, as well as tools for updating and
inspecting different people's Markov models.

To install the stuff, get Bundler and run:

    bundle install

I wish I could give you more help, but I'm a Python guy, not a Ruby guy,
so I forgot how I originally set this up anyway. I think RVM was
involved.


Making Bots
-----------
To use it, copy bots-example.rb to bots.rb, and make the appropriate
changes for your bot's screen name, your screen name, the Twitter API
information, and how you want the bot to behave. Then, download the
initial corpus by running:

    sh update.sh <source username>


Inspecting Models
-----------------
The aforementioned update.sh script downloads Twitter corpuses and
Markov models to the model/ and corpus/ directories. You can examine
the models with the provided scripts:

    ruby make-tweets.rb model/<username>.model 20
    ruby find-keywords.rb model/<username>.model 20

make-tweets generates some sample tweets, and find-keywords determines
the model's most popular keywords. You can use these even without a
configuration file in bots.rb, so you can use it to see what other
people's bots would sound like even if you don't actually make them bots.
