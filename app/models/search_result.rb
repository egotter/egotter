# == Schema Information
#
# Table name: search_results
#
#  id          :integer          not null, primary key
#  uid         :string(191)      not null
#  screen_name :string(191)      not null
#  status_info :text(65535)      not null
#  from_id     :integer          not null
#  query       :string(191)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_search_results_on_created_at   (created_at)
#  index_search_results_on_from_id      (from_id)
#  index_search_results_on_screen_name  (screen_name)
#  index_search_results_on_uid          (uid)
#

class SearchResult < ActiveRecord::Base
  belongs_to :twitter_user

  attr_accessor :client, :login_user, :egotter_context, :without_friends

  delegate *Status::STATUS_SAVE_KEYS.reject { |k| k.in?(%i(id screen_name)) }, to: :status_info_mash

  def status_info_mash
    @status_info_mash ||= Hashie::Mash.new(JSON.parse(status_info))
  end

  def has_key?(key)
    status_info_mash.has_key?(key)
  end

  include Concerns::TwitterUser::Validation
  include Concerns::TwitterUser::Equalizer
end
