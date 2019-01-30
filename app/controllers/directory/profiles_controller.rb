module Directory
  class ProfilesController < ApplicationController

    def show
      id1 = params[:id1]
      id2 = params[:id2]

      if id1.present? && id2.present?
        @screen_names = TwitterUser.uniq.
            where(created_at: (1.days.ago)..(Time.now)).
            where('uid % ? = 0', 10 * id1.to_i + id2.to_i).
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
