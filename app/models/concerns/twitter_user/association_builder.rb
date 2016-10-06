require 'active_support/concern'

module Concerns::TwitterUser::AssociationBuilder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::Validation

  class_methods do
  end

  included do
  end

  def build_relations(client, login_user, context)
    relations = fetch_relations(client, login_user, context)
    build_user_relations(:friends, relations[:friends])
    build_user_relations(:followers, relations[:followers])
    build_status_relations(:statuses, relations[:statuses])
    build_status_relations(:mentions, relations[:mentions])
    build_status_relations(:search_results, relations[:search_results])
    build_status_relations(:favorites, relations[:favorites])

    search_results.each { |sr| sr.query = mention_name }

    true
  end

  private

  # Not using uniq for mentions, search_results and favorites intentionally
  def fetch_relations(client, login_user, context)
    @_fetch_signatures = @_reject_relation_names = nil

    fetch_results = client._fetch_parallelly(fetch_signatures(login_user, context))
    client.replying(uid.to_i) # only create a cache

    fetch_signatures(login_user, context).each_with_object({}).with_index do |(item, memo), i|
      name = item[:method]
      memo[conv_method_name_to_relation_name(name)] = fetch_results[i]
    end
  end

  def conv_method_name_to_relation_name(name)
    case name
      when :user_timeline     then :statuses
      when :search            then :search_results
      when :mentions_timeline then :mentions
      else name
    end
  end

  def all_signatures
    [
      {method: :friends,           args: [uid.to_i]},
      {method: :followers,         args: [uid.to_i]},
      {method: :user_timeline,     args: [uid.to_i]},     # replying
      {method: :search,            args: [mention_name]}, # replied
      {method: :home_timeline,     args: [uid.to_i]},     # TODO cache?
      {method: :mentions_timeline, args: [uid.to_i]},     # replied
      {method: :favorites,         args: [uid.to_i]}      # favoriting
    ]
  end

  def fetch_signatures(login_user, context)
    @_fetch_signatures ||=
      begin
        candidate_names = reject_relation_names(login_user, context)
        all_signatures.dup.delete_if { |item| candidate_names.include?(item[:method]) }
      end
  end

  def reject_relation_names(login_user, context)
    @_reject_relation_names ||=
      case [!!(login_user && login_user.uid.to_i == uid.to_i), too_many_friends?(login_user: login_user, context: context)]
        when [true, true]   then %i(friends followers)
        when [true, false]  then []
        when [false, true]  then %i(friends followers home_timeline mentions_timeline)
        when [false, false] then %i(home_timeline mentions_timeline)
      end
  end

  def build_user_relations(name, objects)
    (objects || []).each do |user|
      obj = send(name).build(
        uid: user.id,
        screen_name: user.screen_name,
      )

      if obj.respond_to?(:user_info)
        obj.user_info = user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json
      end
      if obj.respond_to?(:user_info_gzip)
        obj.user_info_gzip = ActiveSupport::Gzip.compress(user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json)
      end
    end
  end

  def build_status_relations(name, objects)
    (objects || []).each do |status|
      send(name).build(
        uid: status.user.id,
        screen_name: status.user.screen_name,
        status_info: status.slice(*Status::STATUS_SAVE_KEYS).to_json
      )
    end
  end
end
