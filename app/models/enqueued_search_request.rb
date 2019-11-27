class EnqueuedSearchRequest < ::Egotter::SortedSet

  def initialize
    super(Redis.client)

    @ttl = Rails.configuration.x.constants['search_requests']['skip_duplicate_job_interval']
    @key = "#{Rails.env}:#{self.class}:#{@ttl}:any_ids"
  end
end
