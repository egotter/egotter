namespace :blacklist_words do
  desc 'load'
  task load: :environment do
    File.read(ENV['FILE']).split("\n").each do |word|
      BlacklistWord.create(text: word)
    end
  end
end
