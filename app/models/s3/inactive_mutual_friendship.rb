# -*- SkipSchemaAnnotations

module S3
  class InactiveMutualFriendship < Relationship
    class << self
      def bucket_name
        "egotter.#{Rails.env}.inactive-mutual-friendships"
      end
    end
  end
end
