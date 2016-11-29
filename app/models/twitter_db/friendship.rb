module TwitterDB
  class Friendship < TwitterDB::Base
    self.table_name = 'friends_users'
  end
end
