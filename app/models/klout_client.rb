require 'open-uri'
require 'forwardable'

class KloutClient
  extend Forwardable

  def_delegators :@store, :clear, :cleanup

  API_KEY = ENV['KLOUT_API_KEY']

  def initialize
    @store = ActiveSupport::Cache.lookup_store(:file_store, File.expand_path('tmp/klout_cache', ENV['RAILS_ROOT']))
  end

  def score(uid, round: true)
    value = @store.fetch(uid, expires_in: 5.days, race_condition_ttl: 5.minutes) { fetch_score(uid) }
    round ? value.round : value
  end

  private

  def fetch_klout_id(uid)
    res = open("http://api.klout.com/v2/identity.json/tw/#{uid}?key=#{API_KEY}").read
    JSON.parse(res)['id']
  rescue => e
    Rails.logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{uid}"
    nil
  end

  def fetch_score(uid)
    res = open("http://api.klout.com/v2/user.json/#{fetch_klout_id(uid)}/score?key=#{API_KEY}").read
    JSON.parse(res)['score']
  rescue => e
    Rails.logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{uid}"
    nil
  end
end
