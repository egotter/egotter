# == Schema Information
#
# Table name: scores
#
#  id             :integer          not null, primary key
#  uid            :integer          not null
#  klout_id       :string(191)      not null
#  klout_score    :float(53)        not null
#  influence_json :text(65535)      not null
#
# Indexes
#
#  index_scores_on_uid  (uid) UNIQUE
#

require 'open-uri'

class Score < ActiveRecord::Base
  API_KEY = ENV['KLOUT_API_KEY']

  def influence
    name = __method__.to_s
    ivar_name = "@#{name}_cache"
    if instance_variable_defined?(ivar_name)
      instance_variable_get(ivar_name)
    else
      str = send("#{name}_json")
      if str.present?
        instance_variable_set(ivar_name, JSON.parse(str, symbolize_names: true))
      else
        nil
      end
    end
  end

  def will_win
    (influencers + influencees).select { |user| user[:score] < klout_score }.sort_by { |user| -user[:score] }.take(2).map { |user| user[:screen_name] }
  end

  def will_loose
    (influencers + influencees).select { |user| user[:score] > klout_score }.sort_by { |user| -user[:score] }.take(2).map { |user| user[:screen_name] }
  end

  def influencers
    influence[:influencers]
  end

  def influencees
    influence[:influencees]
  end

  def self.builder(uid)
    Builder.new(uid)
  end

  class Builder
    attr_reader :uid

    def initialize(uid)
      @uid = uid.to_i
    end

    def build
      klout_id, score, influence = KloutFetcher.new(uid).fetch
      Score.new(uid: uid, klout_id: klout_id, klout_score: score, influence_json: influence.to_json)
    end
  end

  class KloutFetcher
    attr_reader :uid

    def initialize(uid)
      @uid = uid.to_i
    end

    def fetch
      klout_id = fetch_klout_id(uid)

      if klout_id
        [klout_id, fetch_score(klout_id), fetch_influence(klout_id)]
      else
        [nil, nil, {influencers: [], influencees: []}]
      end
    end

    private

    def fetch_klout_id(uid)
      res = open("http://api.klout.com/v2/identity.json/tw/#{uid}?key=#{API_KEY}").read
      JSON.parse(res)['id']
    rescue => e
      Rails.logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{uid}"
      nil
    end

    def fetch_score(klout_id)
      res = open("http://api.klout.com/v2/user.json/#{klout_id}/score?key=#{API_KEY}").read
      JSON.parse(res)['score']
    rescue => e
      Rails.logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{klout_id}"
      nil
    end

    def fetch_influence(klout_id)
      res = open("http://api.klout.com/v2/user.json/#{klout_id}/influence?key=#{API_KEY}").read
      json = JSON.parse(res)
      {
        influencers: extract_influencers(json),
        influencees: extract_influencees(json)
      }
    rescue => e
      Rails.logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{klout_id}"
      nil
    end

    def extract_influencers(influence)
      influence['myInfluencers'].map { |obj| obj['entity']['payload'] }.map { |obj| {screen_name: obj['nick'], score: obj['score']['score']} }
    end

    def extract_influencees(influence)
      influence['myInfluencees'].map { |obj| obj['entity']['payload'] }.map { |obj| {screen_name: obj['nick'], score: obj['score']['score']} }
    end
  end
end
