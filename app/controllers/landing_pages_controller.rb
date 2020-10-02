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
        else
          'https://egotter.com?via=lp_unknown_name'
        end
  end
end
