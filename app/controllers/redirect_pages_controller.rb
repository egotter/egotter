class RedirectPagesController < ApplicationController
  skip_before_action :current_user_not_blocker?

  after_action do
    if user_signed_in? && @redirect_path.to_s.match?(/\Abaseshop_(1|3|6|12)\z/)
      BaseshopAccessedFlag.on(current_user.id)
    end
  end

  def new
    @redirect_path =
        case params[:name]
        when 'baseshop_1', 'monthly-basis-1'
          'https://bit.ly/baseshop_1'
        when 'baseshop_3', 'monthly-basis-3'
          'https://bit.ly/baseshop_3'
        when 'baseshop_6', 'monthly-basis-6'
          'https://bit.ly/baseshop_6'
        when 'baseshop_12', 'monthly-basis-12'
          'https://bit.ly/baseshop_12'
        else
          'https://egotter.com?via=rp_unknown_name'
        end
  end
end
