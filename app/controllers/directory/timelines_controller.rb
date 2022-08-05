module Directory
  class TimelinesController < ApplicationController

    rescue_from Rack::Timeout::RequestTimeoutException do |e|
      Airbag.exception e, request_details
      head :request_timeout unless performed?
    end

    NUM_REGEXP = /\A\d{1,3}\z/

    def show
      id1 = params[:id1]
      id2 = params[:id2]

      if id1.to_s.match?(NUM_REGEXP) && id2.to_s.match?(NUM_REGEXP)
        @screen_names = TwitterUser.where_mod(id1.to_i, id2.to_i).limit(1000).pluck(:screen_name).sort
        render 'directory/timelines/second_layer'
      elsif id1.to_s.match?(NUM_REGEXP) && id2.blank?
        @id1 = id1
        render 'directory/timelines/first_layer'
      else
        render
      end
    end
  end
end
