require 'active_support/concern'

module Concerns::TwitterUsersConcern
  extend ActiveSupport::Concern

  included do
  end

  def build_twitter_user_by(screen_name:)
    user = request_context_client.user(screen_name)
    twitter_user = TwitterUser.build_by(user: user)

    DeleteNotFoundUserWorker.perform_async(screen_name)
    DeleteForbiddenUserWorker.perform_async(screen_name)

    twitter_user
  rescue => e
    if e.message == 'User not found.'
      CreateNotFoundUserWorker.perform_async(screen_name)
    elsif e.message == 'User has been suspended.'
      CreateForbiddenUserWorker.perform_async(screen_name)
    end

    if can_see_forbidden_or_not_found?(screen_name: screen_name)
      TwitterUser.order(created_at: :desc).find_by(screen_name: screen_name)
    else
      respond_with_error(:bad_request, twitter_exception_messages(e, screen_name))
    end
  end

  def build_twitter_user_by_uid(uid)
    screen_name = request_context_client.user(uid.to_i)[:screen_name]
    build_twitter_user_by(screen_name: screen_name)
  rescue => e
    respond_with_error(:bad_request, twitter_exception_messages(e, "ID #{uid}"))
  end

  def fetch_twitter_user_from_cache(uid)
    attrs = Util::ValidTwitterUserSet.new(Redis.client).get(uid)
    return nil if attrs.nil?

    TwitterUser.new(
        uid: attrs['uid'],
        screen_name: attrs['screen_name'],
        raw_attrs_text: attrs['raw_attrs_text'] || attrs['user_info'],
    )
  end

  def save_twitter_user_to_cache(uid, screen_name, raw_attrs_text)
    attrs = {uid: uid, screen_name: screen_name, raw_attrs_text: raw_attrs_text}
    Util::ValidTwitterUserSet.new(Redis.client).set(uid, attrs)
  end
end
