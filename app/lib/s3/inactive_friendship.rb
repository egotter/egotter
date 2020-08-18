# -*- SkipSchemaAnnotations

module S3
  class InactiveFriendship < Relationship
    class << self
      def bucket_name
        "egotter.#{Rails.env}.inactive-friendships"
      end
    end
  end
end
