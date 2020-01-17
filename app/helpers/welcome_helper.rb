module WelcomeHelper
  def sign_in_with_twitter_link(redirect_path, via, html_options = {}, &block)
    path_options = {via: current_via(via)}
    path_options[:redirect_path] = redirect_path if redirect_path
    if block_given?
      link_to sign_in_path(path_options), html_options, &block
    else
      link_to t('welcome.new.sign_in_with_twitter_html'), sign_in_path(path_options), html_options
    end
  end
end
