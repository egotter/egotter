class UpdateHistoriesDecorator < ApplicationDecorator
  delegate_all

  def created_at
    object.created_at.in_time_zone('Tokyo')
  end

  def updated_at
    object.created_at.in_time_zone('Tokyo')
  end
end
