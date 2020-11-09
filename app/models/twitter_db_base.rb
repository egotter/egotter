class TwitterDBBase < ApplicationRecord
  self.abstract_class = true
  connects_to database: {writing: :twitter_db, reading: :twitter_db}
end
