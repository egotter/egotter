require 'active_support/concern'

module Concerns::TwitterUser::Builder
  extend ActiveSupport::Concern

  class_methods do
    def build_by_user(user, attrs = {})
      build_relation = attrs.has_key?(:build_relation) ? attrs.delete(:build_relation) : false
      tu = new(attrs) do |tu|
        tu.uid = user.id
        tu.screen_name = user.screen_name
        tu.user_info = user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json # TODO check the type of keys and values
      end
      tu.build_relations if build_relation
      tu
    end

    def build_by_client(client, user, attrs = {})
      build_by_user(client.user(user), attrs.merge(client: client))
    end

    def build(client, user, option = {})
      build_by_client(client, user, option)
    end

  end

  included do
    def build_relations
      uid_i = uid.to_i
      search_query = "@#{screen_name}"

      if ego_surfing?
        candidates = [
          {method: :friends_parallelly, args: [uid_i]},
          {method: :followers_parallelly, args: [uid_i]},
          {method: :user_timeline, args: [uid_i]}, # for users_which_you_replied_to
          {method: :search, args: [search_query]}, # for replied
          {method: :home_timeline, args: [uid_i]},
          {method: :mentions_timeline, args: [uid_i]}, # for replied
          {method: :favorites, args: [uid_i]} # for users_which_you_faved
        ]
        if without_friends
          candidates = candidates.slice(2, candidates.size - 2)
          _statuses, _search_results, _, _mentions, _favorites = client._fetch_parallelly(candidates)
          _friends = _followers = []
        else
          _friends, _followers, _statuses, _search_results, _, _mentions, _favorites = client._fetch_parallelly(candidates)
        end
      else
        candidates = [
          {method: :friends_parallelly, args: [uid_i]},
          {method: :followers_parallelly, args: [uid_i]},
          {method: :user_timeline, args: [uid_i]},
          {method: :search, args: [search_query]},
          {method: :favorites, args: [uid_i]}
        ]
        if without_friends
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
                                 {method: :users_which_you_replied_to, args: [uid_i]}
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
end
