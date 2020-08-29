# -*- SkipSchemaAnnotations

module S3
  class CloseFriendship < Relationship
    class << self
      def bucket_name
        "egotter.#{Rails.env}.close-friendships"
      end
    end
  end
end
