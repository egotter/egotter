# == Schema Information
#
# Table name: bots
#
#  id          :integer          not null, primary key
#  uid         :integer          not null
#  screen_name :string(191)      not null
#  secret      :string(191)      not null
#  token       :string(191)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_bots_on_screen_name  (screen_name)
#  index_bots_on_uid          (uid) UNIQUE
#

class Bot < ActiveRecord::Base

  IDS = pluck(:id)

  def self.api_client
    sample.api_client
  end

  def self.sample
    find(IDS.sample)
  end

  def self.load(path)
    JSON.parse(File.read(path)).each do |bot|
      create!(uid: bot['uid'], screen_name: bot['screen_name'], secret: bot['secret'], token: bot['token'])
    end
  end

  def self.verify_credentials
    processed = Queue.new
    Parallel.each(all, in_threads: 10) do |bot|
      processed << {id: bot.id, screen_name: bot.screen_name, status: !!bot.verify_credentials}
    end

    processed.size.times.map { processed.pop }.sort_by { |p| p[:id] }
  end

  def self.rate_limit
    processed = Queue.new
    Parallel.each(all, in_threads: 10) do |bot|
      processed << {id: bot.id, rate_limit: bot.rate_limit}
    end

    processed.size.times.map { processed.pop }.sort_by { |p| p[:id] }.map do |p|
      {
        id: p[:id],
        verify_credentials: p[:rate_limit].verify_credentials,
        friend_ids: p[:rate_limit].friend_ids,
        follower_ids: p[:rate_limit].follower_ids
      }
    end
  end

  def verify_credentials
    api_client.verify_credentials rescue nil
  end

  def rate_limit
    RateLimit.new(api_client.send(:perform_get, '/1.1/application/rate_limit_status.json')) rescue nil
  end

  def api_client
    ApiClient.instance(access_token: token, access_token_secret: secret)
  end

  class RateLimit
    def initialize(status)
      @status = status
    end

    def resources
      @status[:resources]
    end

    def verify_credentials
      {
        remaining: resources[:account][:'/account/verify_credentials'][:remaining],
        reset_in: (Time.zone.at(resources[:account][:'/account/verify_credentials'][:reset]) - Time.zone.now).round
      }
    end

    def friend_ids
      {
        remaining: resources[:friends][:'/friends/ids'][:remaining],
        reset_in: (Time.zone.at(resources[:friends][:'/friends/ids'][:reset]) - Time.zone.now).round
      }
    end

    def follower_ids
      {
        remaining: resources[:followers][:'/followers/ids'][:remaining],
        reset_in: (Time.zone.at(resources[:followers][:'/followers/ids'][:reset]) - Time.zone.now).round
      }
    end
  end
end
