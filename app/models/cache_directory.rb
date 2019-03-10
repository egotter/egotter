# == Schema Information
#
# Table name: cache_directories
#
#  id         :bigint(8)        not null, primary key
#  name       :string(191)      not null
#  dir        :string(191)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_cache_directories_on_dir   (dir) UNIQUE
#  index_cache_directories_on_name  (name) UNIQUE
#

class CacheDirectory < ApplicationRecord
  validates :name, uniqueness: true
  validates :dir, uniqueness: true
end
