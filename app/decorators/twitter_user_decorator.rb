class TwitterUserDecorator < ApplicationDecorator
  delegate_all

  def delimited_statuses_count
    statuses_count.to_i.to_s(:delimited)
  end

  def delimited_friends_count
    friends_count.to_i.to_s(:delimited)
  end

  def delimited_followers_count
    followers_count.to_i.to_s(:delimited)
  end

  def percent_follow_back_rate
    h.number_to_percentage(follow_back_rate * 100, precision: 1) rescue '0.0%'
  end

  def account_created_at?
    account_created_at.present? && !account_created_at.kind_of?(String)
  end

  def location?
    location.present?
  end

  def url?
    url.present?
  end

  def description?
    description.present?
  end

  def profile_banner_url?
    profile_banner_url.present?
  end

  def profile_banner_url_for(request)
    suffix = request.from_pc? ? 'web_retina' : 'mobile_retina'
    "#{profile_banner_url}/#{suffix}"
  end

  def profile_link_color_code
    "##{profile_link_color}"
  end

  def suspended?
    suspended
  end

  def blocked?
    respond_to?(:blocked) && blocked
  end

  def inactive?
    inactive_value =
        if object.respond_to?(:inactive?)
          object.inactive?
        elsif object.respond_to?(:status)
          status&.created_at && Time.parse(status.created_at) < 2.weeks.ago
        end

    !suspended? && inactive_value
  end

  def refollow?
    respond_to?(:refollow) && refollow
  end

  def refollowed?
    respond_to?(:refollowed) && refollowed
  end

  def suspended_label
    suspended? ? '&nbsp;<span class="label label-danger">' + I18n.t('twitter.profile.labels.suspended') + '</span>' : ''
  end

  def blocked_label
    blocked? ? '&nbsp;<span class="label label-default">' + I18n.t('twitter.profile.labels.blocked') + '</span>' : ''
  end

  def inactive_label
    inactive? ? '&nbsp;<span class="label label-default">' + I18n.t('twitter.profile.labels.inactive') + '</span>' : ''
  end

  def refollow_label
    refollow? ? '&nbsp;<span class="label label-info">' + I18n.t('twitter.profile.labels.refollow') + '</span>' : ''
  end

  def refollowed_label
    refollowed? ? '&nbsp;<span class="label label-info">' + I18n.t('twitter.profile.labels.refollowed') + '</span>' : ''
  end

  def status_labels
    "#{suspended_label}#{blocked_label}#{inactive_label}#{refollow_label}#{refollowed_label}".html_safe
  end

  def protected?
    object.protected
  end

  def verified?
    verified
  end

  def protected_icon
    protected? ? '&nbsp;<span class="glyphicon glyphicon-lock"></span>' : ''
  end

  def verified_icon
    verified? ? '&nbsp;<span class="glyphicon glyphicon-ok"></span>' : ''
  end

  def name_with_icon
    "#{name}#{protected_icon}#{verified_icon}".html_safe
  end
end
