require 'active_support/concern'

module Concerns::SessionsConcern
  extend ActiveSupport::Concern

  included do
  end

  def egotter_visit_id
    if from_crawler?
      return -1
    end

    if session[:egotter_visit_id].class != String
      session[:egotter_visit_id] = gen_egotter_visit_id
    end

    session[:egotter_visit_id]
  end

  def gen_egotter_visit_id
    "sess-v2-#{Digest::MD5.hexdigest("#{Time.zone.now.to_i + rand(10000)}")}"
  end
end
