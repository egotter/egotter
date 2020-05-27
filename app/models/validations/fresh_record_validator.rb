module Validations
  class FreshRecordValidator < ActiveModel::Validator
    def validate(new_record)
      latest = TwitterUser.latest_by(uid: new_record.uid)
      return if latest.nil?

      if latest.too_short_create_interval?
        new_record.errors[:base] << "id=#{latest.id} is created #{(Time.zone.now - latest.created_at).to_i} seconds ago"
      end
    end
  end
end
