module WelcomeHelper
  def sign_in_with_twitter_link(redirect_path, via, html_options = {}, &block)
    path_options = {via: current_via(via)}
    path_options[:redirect_path] = redirect_path if redirect_path
    if block_given?
      link_to sign_in_path(path_options), html_options, &block
    else
      icon = user_signed_in? ? tag.img(class: 'rounded-circle', src: current_user_icon, width: 24, height: 24) : tag.i(class: 'fab fa-twitter')
      link_to t('welcome.new.sign_in_with_twitter_html', icon: icon), sign_in_path(path_options), html_options
    end
  end
end
