require 'active_support/concern'

module Concerns::SearchHistoriesConcern
  extend ActiveSupport::Concern
  include Concerns::SessionsConcern

  included do
  end

  def update_search_histories_when_signing_in(user)
    SearchHistory.where(session_id: fingerprint).update_all(user_id: user.id)
    SearchHistory.where(user_id: user.id).update_all(session_id: fingerprint)
  end

  def update_search_histories_when_signing_out(&block)
    old_session_id = fingerprint
    yield
    new_session_id = fingerprint
    SearchHistory.where(session_id: old_session_id).update_all(session_id: new_session_id)
    logger.info "#{old_session_id} turned into #{new_session_id}."
  end
end
