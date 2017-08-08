module TwitterDB
  class Users
    def self.import(t_users)
      users = t_users.map { |user| TwitterDB::User.to_import_format(user) }
      users.sort_by!(&:first)
      TwitterDB::User.import_in_batches(users)
    end
  end
end
