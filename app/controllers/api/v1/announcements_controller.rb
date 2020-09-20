module Api
  module V1
    class AnnouncementsController < ApplicationController

      before_action { self.access_log_disabled = true }

      def list
        render json: {records: Announcement.list.map { |a| {date: a.date, message: a.message} }}
      end
    end
  end
end
