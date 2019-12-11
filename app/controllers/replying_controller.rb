class ReplyingController < ::Page::Base
  include Concerns::FriendsConcern

  def all
    initialize_instance_variables
    @collection = @twitter_user.replying.limit(300)
    render template: 'friends/all' unless performed?
  end

  def show
    initialize_instance_variables
    @active_tab = 0
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
