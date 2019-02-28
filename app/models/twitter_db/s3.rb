# -*- SkipSchemaAnnotations
module TwitterDB
  module S3
    module Api
      def find_by!(uid:)
        text = fetch(uid)
        item = parse_json(text)
        uids = item.has_key?('compress') ? unpack(item[uids_key.to_s]) : item[uids_key.to_s]
        {
            uid: item['uid'],
            screen_name: item['screen_name'],
            uids_key => uids
        }
      end

      def find_by(uid:)
        tries ||= 3
        find_by!(uid: uid)
      rescue Aws::S3::Errors::NoSuchKey => e
        message = "#{self}##{__method__} #{e.class} #{e.message} #{uid}"

        if (tries -= 1) < 0
          Rails.logger.warn "RETRY EXHAUSTED #{message}"
          Rails.logger.info {e.backtrace.join("\n")}
          {}
        else
          Rails.logger.warn "RETRY #{tries} #{message}"
          sleep 0.1
          retry
        end
      end

      def import_by!(user:)
        import_from!(user.uid, user.screen_name, user.send(uids_key))
      end

      def import_from!(uid, screen_name, uids)
        store(uid, encoded_body(uid, screen_name, uids))
      end


      def import!(users)
        users.each {|user| user.send(uids_key)}
        parallel(users) {|user| import_by!(user: user)}
      end

      def encoded_body(uid, screen_name, uids)
        {
            uid: uid,
            screen_name: screen_name,
            uids_key => pack(uids),
            compress: 1
        }.to_json
      end
    end
  end
end
