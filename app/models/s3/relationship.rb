# -*- SkipSchemaAnnotations

module S3
  class Relationship
    attr_reader :uids

    def initialize(uids)
      @uids = uids
    end

    class << self
      def bucket_name
        'not-specified'
      end

      def where(uid: nil)
        obj = client.read(uid)
        obj ? new(decode(obj)['uids']) : nil
      rescue Aws::S3::Errors::NoSuchKey => e
        nil
      end

      def import_from!(uid, uids)
        body = encode(uid, uids)
        client.write(uid, body)
      end

      def delete(uid: nil)
        client.delete(uid)
      end

      def encode(uid, uids)
        {
            uid: uid,
            uids: ::S3::Util.pack(uids),
            time: Time.zone.now.to_s,
        }.to_json
      end

      def decode(obj)
        obj = ::S3::Util.parse_json(obj)
        obj['uids'] = ::S3::Util.unpack(obj['uids'])
        obj
      end

      def client
        @client ||= ::S3::Client.new(bucket_name, self)
      end
    end
  end
end
