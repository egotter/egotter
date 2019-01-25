module WelcomeHelper
  def sign_in_with_twitter_link(redirect_path, via, options = {}, &block)
    link_to t('welcome.new.sign_in_with_twitter'), welcome_path(redirect_path: redirect_path, via: build_via(via)), options, &block
  end
end
