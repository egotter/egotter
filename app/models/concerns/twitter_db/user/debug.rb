require 'active_support/concern'

module Concerns::TwitterDB::User::Debug
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def debug_print_friends
    delim = ' '
    puts([
           [ friends.size,  friendships.size,  friends_size,  friends_count].inspect,
           [ followers.size,  followerships.size,  followers_size,  followers_count].inspect
         ].join delim)
  end

  %i(debug_print_friends).each do |name|
    alias_method "orig_#{name}", name
    define_method(name) do |*args|
      Rails.logger.silence { send("orig_#{name}", *args) }
    end
  end
end
