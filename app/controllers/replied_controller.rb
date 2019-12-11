class RepliedController < ::Page::Base
  include Concerns::FriendsConcern

  def all
    initialize_instance_variables
    @collection = @twitter_user.replied.limit(300)
    render template: 'friends/all' unless performed?
  end

  def show
    initialize_instance_variables
    @active_tab = 1
    render template: 'friends/show' unless performed?
  end

  def related_counts
    values = {}

    Timeout.timeout(2.seconds) do
      values[:replying] = @twitter_user.replying_uids.size
      values[:replied] = @twitter_user.replied_uids(login_user: current_user).size
      values[:replying_and_replied] = @twitter_user.replying_and_replied_uids(login_user: current_user).size
    end

    values
  rescue Timeout::Error => e
    logger.info "#{controller_name}##{__method__} #{e.class} #{e.message} #{@twitter_user.inspect}"
    logger.info e.backtrace.join("\n")

    values[:replying] = -1 unless values.has_key?(:replying)
    values[:replied] = -1 unless values.has_key?(:replied)
    values[:replying_and_replied] = -1 unless values.has_key?(:replying_and_replied)

    values
  end

  def tabs
    [
      {text: t('replying.show.see_replying_html', num: @twitter_user.replying_uids.size), url: replying_path(@twitter_user)},
      {text: t('replying.show.see_replied_html', num: @twitter_user.replied_uids(login_user: current_user).size), url: replied_path(@twitter_user)},
      {text: t('replying.show.see_replying_and_replied_html', num: @twitter_user.replying_and_replied_uids(login_user: current_user).size), url: replying_and_replied_path(@twitter_user)}
    ]
  end
end
