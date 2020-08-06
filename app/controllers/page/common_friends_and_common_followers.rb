class Page::CommonFriendsAndCommonFollowers < ::Page::Base
  before_action(only: %i(show all)) { require_login! }
  before_action(only: %i(show all)) { twitter_user_persisted?(current_user.uid) }

  def all
    initialize_instance_variables
    @collection = @twitter_user.common_users_by(controller_name: controller_name, friend: current_user.twitter_user)
  end

  def show
    initialize_instance_variables
  end

  private

  def initialize_instance_variables
    @api_path = send("api_v1_#{controller_name}_list_path")
    @canonical_url = send("#{controller_name.singularize}_url", @twitter_user)

    counts = view_context.current_counts(@twitter_user)

    @tweet_text = t('.tweet_text', {user: @twitter_user.mention_name, user2: current_user.twitter_user.mention_name, url: @canonical_url}.merge(counts))
  end
end
