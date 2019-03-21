require 'active_support/concern'

module Concerns::Report::Readable
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    scope :read, -> {where.not(read_at: nil)}
    scope :unread, -> {where(read_at: nil)}
  end

  def read?
    !read_at.nil?
  end
end