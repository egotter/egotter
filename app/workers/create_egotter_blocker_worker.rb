# TODO Remove later
class CreateEgotterBlockerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def perform(*)
  end
end
