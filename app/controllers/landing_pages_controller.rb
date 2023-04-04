class LandingPagesController < ApplicationController
  def new
    @redirect_path =
        case params[:name]
        when 'register'
          'https://bit.ly/egotter_sign_in'
        when 'faq'
          'https://bit.ly/egotter_faq'
        when 'top'
          'https://bit.ly/egotter_top2'
        when 'tweet'
          'https://bit.ly/egotter_tweet'
        when 'new_plan'
          'https://bit.ly/new_plan0430'
        when 'cancel_plan'
          'https://bit.ly/cancel_plan'
        else
          'https://egotter.com?via=lp_unknown_name'
        end
  end
end
