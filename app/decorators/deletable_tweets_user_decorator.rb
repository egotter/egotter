class DeletableTweetsUserDecorator
  def initialize(user)
    @user = user
  end

  def to_json
    twitter_db_user = TwitterDB::User.find_by(uid: @user.uid)
    {
        id: @user.uid.to_s,
        screen_name: @user.screen_name,
        name: twitter_db_user&.name,
        profile_image_url: twitter_db_user&.profile_image_url_https,
    }
  end
end
