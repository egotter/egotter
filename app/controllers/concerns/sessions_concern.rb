require 'active_support/concern'

module Concerns::SessionsConcern
  extend ActiveSupport::Concern

  included do
  end

  def egotter_visit_id
    if from_crawler?
      return -1
    end

    if session[:egotter_visit_id].nil? || session[:egotter_visit_id].to_s == '-1'
      session[:egotter_visit_id] = session.id.nil? ? '-1' : session.id
    end

    if session[:egotter_visit_id] == '-1'
      digest = Digest::MD5.hexdigest("#{Time.zone.now.to_i + rand(1000)}")
      session[:egotter_visit_id] = "digest-#{digest}"
    end

    session[:egotter_visit_id]
  end
end
