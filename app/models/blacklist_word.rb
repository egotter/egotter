# == Schema Information
#
# Table name: blacklist_words
#
#  id         :integer          not null, primary key
#  text       :string(191)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_blacklist_words_on_created_at  (created_at)
#  index_blacklist_words_on_text        (text) UNIQUE
#

class BlacklistWord < ActiveRecord::Base
  validates :text, uniqueness: true
end
