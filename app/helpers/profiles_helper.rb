module ProfilesHelper
  def switch_to_twitter_db_user?(user)
    user.respond_to?(:persisted?) && user.persisted? &&
        user.respond_to?(:twitter_db_user) && user.twitter_db_user&.persisted? &&
        user.updated_at <= user.twitter_db_user.updated_at
  end
end
