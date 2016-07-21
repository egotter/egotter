# == Schema Information
#
# Table name: favorites
#
#  id          :integer          not null, primary key
#  uid         :string(191)      not null
#  screen_name :string(191)      not null
#  status_info :text(65535)      not null
#  from_id     :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_favorites_on_created_at   (created_at)
#  index_favorites_on_from_id      (from_id)
#  index_favorites_on_screen_name  (screen_name)
#  index_favorites_on_uid          (uid)
#

class Favorite < ActiveRecord::Base
  belongs_to :twitter_user

  attr_accessor :egotter_context

  include Concerns::Status::Store
  include Concerns::TwitterUser::Validation
  include Concerns::TwitterUser::Equalizer
end
