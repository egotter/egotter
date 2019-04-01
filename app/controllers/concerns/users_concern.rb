require 'active_support/concern'

module Concerns::UsersConcern
  extend ActiveSupport::Concern

  included do
  end

  def current_user_id
    @current_user_id ||= user_signed_in? ? current_user.id : -1
  end
end
