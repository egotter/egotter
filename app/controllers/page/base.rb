module Page
  class Base < ApplicationController
    include Concerns::Showable
    include Concerns::Indexable

    before_action only: :all do
      if !user_signed_in? && !from_crawler?
        via = "#{controller_name}/#{action_name}/need_login"
        redirect_path = send("all_#{controller_name}_path", @twitter_user)

        if request.referer.to_s.empty?
          # Prevent from redirect loop
          url = kick_out_error_path('need_login', redirect_path: redirect_path)
          redirect_to root_path_for(controller: controller_name), alert: t('before_sign_in.need_login_html', url: url)
        else
          redirect_to sign_in_path(via: via, redirect_path: redirect_path)
        end
      end
    end
  end
end