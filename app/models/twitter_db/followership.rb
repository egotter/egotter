module TwitterDB
  class Followership < TwitterDB::Base
    self.table_name = 'followers_users'
  end
end
