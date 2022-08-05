module Directory
  class TimelinesController < ApplicationController

    NUM_REGEXP = TwitterUser::WHERE_MOD_REGEXP

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
