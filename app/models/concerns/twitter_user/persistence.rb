require 'active_support/concern'

module Concerns::TwitterUser::Persistence
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def save(*)
    if invalid? || recently_created_record_exists? || same_record_exists?
      logger.warn "#{self.class}##{__method__} #{errors.full_messages}"
      return false
    end

    _friends, _followers, _statuses, _mentions, _search_results, _favorites =
      friends.to_a.dup, followers.to_a.dup,
        statuses.to_a.dup, mentions.to_a.dup, search_results.to_a.dup, favorites.to_a.dup
    self.friends = self.followers = self.statuses = self.mentions = self.search_results = self.favorites = []
    super(validate: false)

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

      self.reload
    rescue => e
      logger.warn "#{self.class}##{__method__}: #{e} #{e.message}"
      self.destroy
      false
    else
      true
    end
  end
end