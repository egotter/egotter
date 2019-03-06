class UpdateVisitorWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    visitor = Visitor.find_or_initialize_by(session_id: attrs['session_id'])

    if visitor.new_record?
      visitor.assign_attributes(first_access_at: attrs['created_at'])
    end

    visitor.assign_attributes(last_access_at: attrs['created_at'])

    if attrs['user_id'] != -1
      visitor.assign_attributes(user_id: attrs['user_id'])
    end

    visitor.save!

  rescue ActiveRecord::RecordNotUnique => e
    logger.info e.message.truncate(100)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{attrs.inspect}"
  end
end
