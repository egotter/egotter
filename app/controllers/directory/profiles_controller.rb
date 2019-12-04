module Directory
  class ProfilesController < ApplicationController

    def show
      id1 = params[:id1]
      id2 = params[:id2]

      if id1.to_s.match?(/\A\d{1,2}\z/) && id2.to_s.match?(/\A\d{1,2}\z/)
        @screen_names = TwitterUser.distinct.
            where(created_at: 1.days.ago..Time.zone.now).
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
