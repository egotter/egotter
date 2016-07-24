module ApplicationHelper
  def under_maintenance?
    ENV['MAINTENANCE'].present? || action_name == 'maintenance'
  end

  def show_maintenance_page?
    (under_maintenance? && !admin_signed_in?) || action_name == 'maintenance'
  end

  def redis
    @redis ||= Redis.client
  end

  def client
    @client ||= (user_signed_in? ? current_user.api_client : Bot.api_client)
  end

  def admin_signed_in?
    user_signed_in? && current_user.admin?
  end

  def twitter_link(screen_name)
    view_context.link_to("@#{screen_name}", "https://twitter.com/#{screen_name}", target: '_blank')
  end

  def sign_in_link
    ActiveSupport::Deprecation.warn(<<-MESSAGE.strip_heredoc)
          `#{__method__}` is deprecated.
    MESSAGE
    view_context.link_to(t('dictionary.sign_in'), welcome_path)
  end

  def sign_out_link
    view_context.link_to(t('dictionary.sign_out'), sign_out_path)
  end

  def search_oneself?(uid)
    user_signed_in? && current_user.uid.to_i == uid.to_i
  end

  def search_others?(uid)
    user_signed_in? && current_user.uid.to_i != uid.to_i
  end

  def current_user_id
    user_signed_in? ? current_user.id : -1
  end
end
