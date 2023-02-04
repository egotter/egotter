class ApplicationTwitterRecord < ApplicationRecord
  self.abstract_class = true
  connects_to database: {writing: :twitter, reading: :twitter}
end
