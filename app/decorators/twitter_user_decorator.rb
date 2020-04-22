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
    h.number_to_percentage(follow_back_rate * 100, precision: 1) rescue I18n.t('twitter.profile.unknown_follow_back_rate')
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

  def profile_icon_url?
    profile_image_url_https.present?
  end

  def profile_icon_url_for(request)
    profile_image_url_https.remove('_normal')
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
    object.suspended
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

  def active?
    !inactive?
  end

  def refollow?
    respond_to?(:refollow) && refollow
  end

  def refollowed?
    respond_to?(:refollowed) && refollowed
  end

  def suspended_label
    suspended? ? '&nbsp;<span class="badge badge-danger">' + I18n.t('twitter.profile.labels.suspended') + '</span>' : ''
  end

  def blocked_label
    blocked? ? '&nbsp;<span class="badge badge-secondary">' + I18n.t('twitter.profile.labels.blocked') + '</span>' : ''
  end

  def inactive_label
    inactive? ? '&nbsp;<span class="badge badge-secondary">' + I18n.t('twitter.profile.labels.inactive') + '</span>' : ''
  end

  def refollow_label
    refollow? ? '&nbsp;<span class="badge badge-info">' + I18n.t('twitter.profile.labels.refollow') + '</span>' : ''
  end

  def refollowed_label
    refollowed? ? '&nbsp;<span class="badge badge-info">' + I18n.t('twitter.profile.labels.refollowed') + '</span>' : ''
  end

  def status_labels
    "#{suspended_label}#{blocked_label}#{inactive_label}#{refollow_label}#{refollowed_label}".html_safe
  end

  def followed_label_and_text
    %Q(<i class="fas fa-user" style="color: #bbb;"></i>&nbsp;<span style="color: #bbb;">#{I18n.t('twitter.profile.labels.followed')}</span>).html_safe
  end

  def protected?
    object.protected
  end

  def verified?
    verified
  end

  def protected_icon
    if protected?
      <<~HTML.html_safe
        &nbsp;<i class="fas fa-lock text-warning"></i>
      HTML
    else
      ''
    end
  end

  def verified_icon
    if verified?
      <<~HTML.html_safe
        &nbsp;<i class="fas fa-check text-primary"></i>
      HTML
    else
      ''
    end
  end

  def name_with_icon
    "#{name}#{protected_icon}#{verified_icon}".html_safe
  end

  def uid_i
    uid.to_i
  end
end
