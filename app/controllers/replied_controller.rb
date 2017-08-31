class RepliedController < FriendsAndFollowers
  include Concerns::Validation
  include SearchesHelper

  def all
    super
    render template: 'friends/all' unless performed?
  end

  def show
    super
    @active_tab = 1
    render template: 'friends/show' unless performed?
  end

  def related_counts
    {
      replying: @twitter_user.replying_uids.size,
      replied: @twitter_user.replied_uids(login_user: current_user).size,
      replying_and_replied: @twitter_user.replying_and_replied_uids(login_user: current_user).size
    }
  end

  def tabs
    [
      {text: t('replying.show.see_replying_html', num: @twitter_user.replying_uids.size), url: replying_path(@twitter_user)},
      {text: t('replying.show.see_replied_html', num: @twitter_user.replied_uids(login_user: current_user).size), url: replied_path(@twitter_user)},
      {text: t('replying.show.see_replying_and_replied_html', num: @twitter_user.replying_and_replied_uids(login_user: current_user).size), url: replying_and_replied_path(@twitter_user)}
    ]
  end
end
