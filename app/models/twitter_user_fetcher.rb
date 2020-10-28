# TODO Refactoring and adding test cases
class TwitterUserFetcher
  attr_reader :api_name

  def initialize(twitter_user, login_user:, context:)
    @uid = twitter_user.uid
    # TODO Try disabling the cache for speed
    @client = (login_user || Bot).api_client
    @login_user = login_user
    @twitter_user = twitter_user
    @context = context
  end

  # Not using uniq for mentions, search_results and favorites intentionally
  def fetch
    reject_names = reject_relation_names
    signatures = fetch_signatures(reject_names)

    if @context == :reporting
      # Requests/24-hour window 100,000
      signatures.delete_if { |hash| hash[:method] == :user_timeline }
    end

    # fetch_results =
    #   client.parallel do |batch|
    #     signatures.each { |signature| batch.send(signature[:method], *signature[:args]) }
    #   end

    signatures.each_with_object({}).with_index do |(item, memo), i|
      # memo[item[:method]] = fetch_results[i]
      @api_name = item[:method]
      memo[item[:method]] = @client.send(item[:method], *item[:args])
    rescue => e
      if negligible_error?(item[:method], e)
        Rails.logger.warn "#{self.class}##{__method__}: Ignore specific errors for #{item[:method]} user_id=#{@login_user&.id} uid=#{@uid}"
        memo[item[:method]] = []
      else
        raise
      end
    end
  end

  private

  def negligible_error?(method_name, error)
    %i(user_timeline mentions_timeline favorites).include?(method_name) &&
        (TwitterApiStatus.too_many_requests?(error) || ServiceStatus.internal_server_error?(error))
  end

  def fetch_signatures(reject_names)
    [
      {method: :friend_ids,        args: [@uid]},
      {method: :follower_ids,      args: [@uid]},
      {method: :user_timeline,     args: [@uid, {include_rts: false}]},     # replying
      sign_in_yourself? ? {method: :mentions_timeline, args: []} : {method: :search, args: [search_query]}, # replied
      {method: :favorites,         args: [@uid]}      # favoriting
    ].delete_if { |item| reject_names.include?(item[:method]) }
  end

  def reject_relation_names
    case [sign_in_yourself?, SearchLimitation.limited?(@twitter_user, signed_in: @login_user)]
      when [true, true]   then %i(friend_ids follower_ids)
      when [true, false]  then []
      when [false, true]  then %i(friend_ids follower_ids)
      when [false, false] then []
    end
  end

  def search_query
    "@#{@twitter_user.screen_name}"
  end

  def sign_in_yourself?
    @login_user&.uid == @uid
  end
end
