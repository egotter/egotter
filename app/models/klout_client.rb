require 'open-uri'
require 'forwardable'

class KloutClient
  extend Forwardable

  def_delegators :@cache, :clear, :cleanup

  API_KEY = ENV['KLOUT_API_KEY']

  def initialize
    @cache = ActiveSupport::Cache.lookup_store(:file_store, File.expand_path('tmp/klout_cache', ENV['RAILS_ROOT']))
  end

  def score(uid)
    key = "score:#{uid}"
    value = @cache.fetch(key, expires_in: 10.days, race_condition_ttl: 5.minutes) { fetch_score(uid) }
    unless value
      value = 0.0
      @cache.write(key, value, expires_in: 5.minutes, race_condition_ttl: 1.minutes)
    end
    value
  end

  def influence(uid)
    key = "influence:#{uid}"
    value = @cache.fetch(key, expires_in: 10.days, race_condition_ttl: 5.minutes) { fetch_influence(uid) }
    if value
      value = JSON.parse(value, symbolize_names: true)
    else
      value = {influencers: [], influencees: []}
      @cache.write(key, value, expires_in: 5.minutes, race_condition_ttl: 1.minutes)
    end
    value
  end

  def klout_id(uid)
    key = "klout_id:#{uid}"
    value = @cache.fetch(key, expires_in: 10.days, race_condition_ttl: 5.minutes) { fetch_klout_id(uid) }
    unless value
      @cache.delete(key)
    end
    value
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
    res = open("http://api.klout.com/v2/user.json/#{klout_id(uid)}/score?key=#{API_KEY}").read
    JSON.parse(res)['score']
  rescue => e
    Rails.logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{uid}"
    nil
  end

  def fetch_influence(uid)
    res = open("http://api.klout.com/v2/user.json/#{klout_id(uid)}/influence?key=#{API_KEY}").read
    json = JSON.parse(res)
    {
      influencers: extract_influencers(json),
      influencees: extract_influencees(json)
    }.to_json
  rescue => e
    Rails.logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{uid}"
    nil
  end

  def extract_influencers(influence)
    influence['myInfluencers'].map { |obj| obj['entity']['payload'] }.map { |obj| {screen_name: obj['nick'], score: obj['score']['score']} }
  end

  def extract_influencees(influence)
    influence['myInfluencees'].map { |obj| obj['entity']['payload'] }.map { |obj| {screen_name: obj['nick'], score: obj['score']['score']} }
  end
end
