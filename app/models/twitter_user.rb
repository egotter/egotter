# == Schema Information
#
# Table name: twitter_users
#
#  id           :integer          not null, primary key
#  uid          :string(191)      not null
#  screen_name  :string(191)      not null
#  user_info    :text(65535)      not null
#  search_count :integer          default(0), not null
#  update_count :integer          default(0), not null
#  user_id      :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_twitter_users_on_created_at               (created_at)
#  index_twitter_users_on_screen_name              (screen_name)
#  index_twitter_users_on_screen_name_and_user_id  (screen_name,user_id)
#  index_twitter_users_on_uid                      (uid)
#  index_twitter_users_on_uid_and_user_id          (uid,user_id)
#

class TwitterUser < ActiveRecord::Base
  with_options foreign_key: :from_id, dependent: :destroy, validate: false do |obj|
    obj.has_many :friends
    obj.has_many :followers
    obj.has_many :statuses
    obj.has_many :mentions
    obj.has_many :search_results
    obj.has_many :favorites
  end

  attr_accessor :client, :egotter_context

  def login_user
    User.find_by(id: user_id)
  end

  include Concerns::TwitterUser::Store
  include Concerns::TwitterUser::Validation
  include Concerns::TwitterUser::Equalizer
  include Concerns::TwitterUser::Builder
  include Concerns::TwitterUser::Utils
  include Concerns::TwitterUser::Api

  def friend_uids
    new_record? ? friends.map { |f| f.uid.to_i } : friends.pluck(:uid).map { |uid| uid.to_i }
  end

  def follower_uids
    new_record? ? followers.map { |f| f.uid.to_i } : followers.pluck(:uid).map { |uid| uid.to_i }
  end

  def diff(other, options = {})
    older = self
    newer = other

    keys = %i(friends_count followers_count friends followers)
    keys.select! { |k| k.in?(options[:only]) } if options.has_key?(:only)

    {
      friends_count: [older.friends_count, newer.friends_count],
      followers_count: [older.followers_count, newer.followers_count],
      friends: [older.friend_uids.size, newer.friend_uids.size],
      followers: [older.follower_uids.size, newer.follower_uids.size]
    }.slice(*keys).reject { |_, v| v[0] == v[1] }
  end

  def save_with_bulk_insert(validate = true)
    if validate && !(valid? && !recently_created_record_exists? && !same_record_exists?)
      logger.warn "#{self.class}##{__method__} #{errors.full_messages}"
      return false
    end

    _friends, _followers, _statuses, _mentions, _search_results, _favorites =
      friends.to_a.dup, followers.to_a.dup,
        statuses.to_a.dup, mentions.to_a.dup, search_results.to_a.dup, favorites.to_a.dup
    self.friends = self.followers = self.statuses = self.mentions = self.search_results = self.favorites = []
    save(validate: false)

    begin
      log_level = Rails.logger.level; Rails.logger.level = Logger::WARN

      self.transaction do
        _friends.map { |f| f.from_id = self.id }
        _friends.each_slice(100).each { |f| Friend.import(f, validate: false) }
      end

      self.transaction do
        _followers.map { |f| f.from_id = self.id }
        _followers.each_slice(100).each { |f| Follower.import(f, validate: false) }
      end

      self.transaction do
        _statuses.map { |s| s.from_id = self.id }
        _statuses.each_slice(100).each { |s| Status.import(s, validate: false) }
      end

      self.transaction do
        _mentions.map { |m| m.from_id = self.id }
        _mentions.each_slice(100).each { |m| Mention.import(m, validate: false) }
      end

      self.transaction do
        _search_results.map { |sr| sr.from_id = self.id }
        _search_results.each_slice(100).each { |sr| SearchResult.import(sr, validate: false) }
      end

      self.transaction do
        _favorites.map { |f| f.from_id = self.id }
        _favorites.each_slice(100).each { |f| Favorite.import(f, validate: false) }
      end

      Rails.logger.level = log_level

      self.reload # for friends, followers and statuses
    rescue => e
      self.destroy
      false
    else
      true
    end
  end

  def search_log
    # TODO need to use user_id?
    log = BackgroundSearchLog.order(created_at: :desc).find_by(uid: uid)
    Hashie::Mash.new(log.nil? ? {} : log.attributes)
  end
end
