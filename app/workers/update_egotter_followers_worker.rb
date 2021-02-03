class UpdateEgotterFollowersWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def unique_in
    30.minutes
  end

  def _timeout_in
    3.minute
  end

  def expire_in
    10.minutes
  end

  # options:
  def perform(options = {})
    uids = collect_follower_uids
    import_follower_uids(uids)
    uids = filter_missing_uids(uids)
    delete_missing_uids(uids)
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(200)} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  private

  def collect_follower_uids(uid = User::EGOTTER_UID)
    options = {count: 5000, cursor: -1}
    collection = []

    50.times do
      client = Bot.api_client.twitter
      response = client.follower_ids(uid, options)
      break if response.nil?

      attrs = response.attrs
      collection.concat(attrs[:ids])

      break if attrs[:next_cursor] == 0

      options[:cursor] = attrs[:next_cursor]
    end

    collection
  end

  def import_follower_uids(uids)
    uids.each_slice(1000).with_index do |uids_array, i|
      users = uids_array.map.with_index { |uid, i| EgotterFollower.new(uid: uid, screen_name: "sn#{i}") }
      benchmark("import uids chunk=#{i}") do
        EgotterFollower.import users, on_duplicate_key_update: %i(uid), validate: false
      end
    end
  end

  def filter_missing_uids(uids)
    not_found_uids = []

    uids.each_slice(5000).with_index do |uids_array, i|
      benchmark("filter uids chunk=#{i}") do
        found_uids = EgotterFollower.where(uid: uids_array).pluck(:uid)
        not_found_uids.concat(uids_array - found_uids)
      end
    end

    not_found_uids
  end

  def delete_missing_uids(uids)
    uids.each_slice(1000).with_index do |uids_array, i|
      benchmark("delete uids chunk=#{i}") do
        EgotterFollower.where(uid: uids_array).delete_all
      end
    end
  end

  def benchmark(message, &block)
    ApplicationRecord.benchmark("Benchmark UpdateEgotterFollowersWorker #{message}", level: :info) do
      Rails.logger.silence(&block)
    end
  end
end
