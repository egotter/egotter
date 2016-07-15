require 'active_support/concern'

module Concerns::TwitterUser::Builder
  extend ActiveSupport::Concern

  class_methods do
    def _basic_build(user, user_id, egotter_context)
      tu = TwitterUser.new(
        uid: user.id,
        screen_name: user.screen_name,
        user_info: user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, # TODO check the type of keys and values
        user_id: user_id
      )
      tu.egotter_context = egotter_context unless egotter_context.nil?
      tu
    end

    def build_with_relations(client, uid, user_id, egotter_context = nil)
      tu = _basic_build(client.user(uid.to_i), user_id, egotter_context)
      tu._build_relations(client)
      tu
    end

    def build_without_relations(client, uid, user_id, egotter_context = nil)
      _basic_build(client.user(uid.to_i), user_id, egotter_context)
    end
  end

  included do
  end

    def _build_relations(client)
      uid_i = uid.to_i
      search_query = "@#{screen_name}"

      if ego_surfing?
        candidates = [
          {method: :friends, args: [uid_i]},
          {method: :followers, args: [uid_i]},
          {method: :user_timeline, args: [uid_i]}, # for users_which_you_replied_to
          {method: :search, args: [search_query]}, # for users_who_replied_to_you
          {method: :home_timeline, args: [uid_i]},
          {method: :mentions_timeline, args: [uid_i]}, # for users_who_replied_to_you
          {method: :favorites, args: [uid_i]} # for users_which_you_faved
        ]
        if too_many_friends?
          candidates = candidates.slice(2, candidates.size - 2)
          _statuses, _search_results, _, _mentions, _favorites = client._fetch_parallelly(candidates)
          _friends = _followers = []
        else
          _friends, _followers, _statuses, _search_results, _, _mentions, _favorites = client._fetch_parallelly(candidates)
        end
      else
        candidates = [
          {method: :friends, args: [uid_i]},
          {method: :followers, args: [uid_i]},
          {method: :user_timeline, args: [uid_i]},
          {method: :search, args: [search_query]},
          {method: :favorites, args: [uid_i]}
        ]
        if too_many_friends?
          candidates = candidates.slice(2, candidates.size - 2)
          _statuses, _search_results, _favorites = client._fetch_parallelly(candidates)
          _friends = _followers = []
        else
          _friends, _followers, _statuses, _search_results, _favorites = client._fetch_parallelly(candidates)
        end
        _mentions = []
      end

      # Not using uniq for mentions, search_results and favorites intentionally

      client._fetch_parallelly([
                                 {method: :replying, args: [uid_i]} # TODO create cache?
                               ])

      _friends.each do |f|
        friends.build(uid: f.id,
                      screen_name: f.screen_name,
                      user_info: f.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json)
      end

      _followers.each do |f|
        followers.build(uid: f.id,
                        screen_name: f.screen_name,
                        user_info: f.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json)
      end

      _statuses.each do |s|
        statuses.build(uid: uid,
                       screen_name: screen_name,
                       status_info: s.slice(*Status::STATUS_SAVE_KEYS).to_json)
      end

      _mentions.each do |m|
        mentions.build(uid: m.user.id,
                       screen_name: m.user.screen_name,
                       status_info: m.slice(*Status::STATUS_SAVE_KEYS).to_json)
      end

      _search_results.each do |sr|
        search_results.build(uid: sr.user.id,
                             screen_name: sr.user.screen_name,
                             status_info: sr.slice(*Status::STATUS_SAVE_KEYS).to_json,
                             query: search_query)
      end

      _favorites.each do |f|
        favorites.build(uid: f.user.id,
                        screen_name: f.user.screen_name,
                        status_info: f.slice(*Status::STATUS_SAVE_KEYS).to_json)
      end

      true
    end
end
