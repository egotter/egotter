module Directory
  class ProfilesController < ApplicationController

    def show
      id1 = params[:id1]
      id2 = params[:id2]

      if id1.present? && id2.present?
        @screen_names = TwitterUser.order(created_at: :desc).
            where('uid % :id1 = 0 and (uid % :id1) % :id2 = 0', id1: id1.to_i, id2: id2.to_i).
            limit(1000).
            pluck(:screen_name)
        render 'directory/profiles/second_layer'
      elsif id1.present? && id2.blank?
        @id1 = id1
        render 'directory/profiles/first_layer'
      else
        render
      end
    end
  end
end
