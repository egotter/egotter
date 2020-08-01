# == Schema Information
#
# Table name: personality_insights
#
#  id         :bigint(8)        not null, primary key
#  uid        :bigint(8)        not null
#  profile    :json
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_personality_insights_on_created_at  (created_at)
#  index_personality_insights_on_uid         (uid) UNIQUE
#

require 'net/http'

class PersonalityInsight < ApplicationRecord

  validates :uid, presence: true, uniqueness: true

  %w(
      word_count
      processed_language
      behavior
      consumption_preferences
      warnings
  ).each do |method|
    define_method(method) do
      profile.send(:[], method)
    end
  end

  def personality_traits
    profile['personality']
  end

  def openness_trait
    profile['personality'].find { |t| t['trait_id'] == 'big5_openness' }
  end

  def conscientiousness_trait
    profile['personality'].find { |t| t['trait_id'] == 'big5_conscientiousness' }
  end

  def extraversion_trait
    profile['personality'].find { |t| t['trait_id'] == 'big5_extraversion' }
  end

  def agreeableness_trait
    profile['personality'].find { |t| t['trait_id'] == 'big5_agreeableness' }
  end

  def neuroticism_trait
    profile['personality'].find { |t| t['trait_id'] == 'big5_neuroticism' }
  end

  def openness_facets
    openness_trait['children']
  end

  def conscientiousness_facets
    conscientiousness_trait['children']
  end

  def extraversion_facets
    extraversion_trait['children']
  end

  def agreeableness_facets
    agreeableness_trait['children']
  end

  def neuroticism_facets
    neuroticism_trait['children']
  end

  def needs_traits
    profile['needs']
  end

  def values_traits
    profile['values']
  end

  def personality_scores
    profile['personality'].map do |trait|
      [trait['trait_id'].to_sym, sprintf('%d', trait['raw_score'] * 100)]
    end.to_h
  end

  def tweets_not_enough?
    profile && profile['error'] == 'tweets not enough'
  end

  def analyzing_failed?
    profile && (profile['error'] || !profile['personality'])
  end

  class << self
    def build(uid, tweets, lang: 'ja')
      payload = build_content_items(tweets, lang)
      new(uid: uid, profile: fetch_profile(payload, lang))
    end

    def sufficient_tweets?(tweets)
      extract_text(tweets).bytesize > 27000
    end

    private

    def extract_text(tweets)
      tweets.select { |t| !t[:text].start_with?('RT') }.map { |t| t[:text].gsub(%r{https://t\.co/[a-zA-Z0-9]+}, '').gsub("\n", ' ') }.join(' ')
    end

    def build_content_items(tweets, lang)
      {
          contentItems: tweets.select { |t| !t[:text].start_with?('RT') }.map do |tweet|
            {
                id: tweet[:id].to_s, contenttype: 'text/plain',
                content: tweet[:text].gsub(%r{https://t\.co/[a-zA-Z0-9]+}, '').gsub("\n", ' '),
                created: Time.zone.parse(tweet[:created_at]).to_i * 1000,
                language: lang
            }
          end
      }
    end

    def fetch_profile(payload, lang)
      uri = URI.parse(ENV['PERSONALITY_INSIGHTS_URL'])
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.open_timeout = 3
      https.read_timeout = 3
      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/json;charset=utf-8'
      req['Content-Language'] = lang
      req['Accept'] = 'application/json'
      req.basic_auth('apikey', ENV['PERSONALITY_INSIGHTS_IAM_APIKEY'])
      req.body = payload.to_json
      res = https.start { https.request(req) }
      JSON.parse(res.body)
    ensure
      CallPersonalityInsightCount.new.increment
    end
  end
end
