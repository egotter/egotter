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

  attr_accessor :egotter_context

  include Concerns::Status::Store
  include Concerns::TwitterUser::Validation
  include Concerns::TwitterUser::Equalizer
end
