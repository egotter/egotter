class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def silent_transaction(&block)
    Rails.logger.silence { ActiveRecord::Base.transaction(&block) }
  end
end
