class TwitterUserFetcher
  attr_reader :uid, :client, :login_user, :twitter_user

  def initialize(twitter_user, client:, login_user:)
    @uid = twitter_user.uid.to_i
    @client = client
    @login_user = login_user
    @twitter_user = twitter_user
  end

  def search_query
    "@#{twitter_user.screen_name}"
  end

  def fetch
    relations = fetch_relations # This process takes a few seconds.
    if %i(friend_ids follower_ids).all? { |key| relations.has_key?(key) }
      CreateFriendsAndFollowersWorker.perform_async(login_user ? login_user.id : -1, uid)
    end
    relations
  end

  # Not using uniq for mentions, search_results and favorites intentionally
  def fetch_relations
    reject_names = reject_relation_names
    signatures = fetch_signatures(reject_names)
    fetch_results = client._fetch_parallelly(signatures)
    client.replying(uid) # only create a cache

    signatures.each_with_object({}).with_index do |(item, memo), i|
      memo[item[:method]] = fetch_results[i]
    end
  end

  def fetch_signatures(reject_names)
    [
      {method: :friend_ids,        args: [uid]},
      {method: :follower_ids,      args: [uid]},
      {method: :user_timeline,     args: [uid, {include_rts: false}]},     # replying
      {method: :search,            args: [search_query]}, # replied
      {method: :home_timeline,     args: [uid]},     # TODO cache?
      {method: :mentions_timeline, args: [uid]},     # replied
      {method: :favorites,         args: [uid]}      # favoriting
    ].delete_if { |item| reject_names.include?(item[:method]) }
  end

  def reject_relation_names
    case [login_user&.uid&.to_i == uid, twitter_user.too_many_friends?(login_user: login_user)]
      when [true, true]   then %i(friend_ids follower_ids)
      when [true, false]  then []
      when [false, true]  then %i(friend_ids follower_ids home_timeline mentions_timeline)
      when [false, false] then %i(home_timeline mentions_timeline)
    end
  end
end