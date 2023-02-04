class ApplicationLogRecord < ApplicationRecord
  self.abstract_class = true
  connects_to database: {writing: :log, reading: :log}
end
