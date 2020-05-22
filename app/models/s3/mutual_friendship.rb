# -*- SkipSchemaAnnotations

module S3
  class MutualFriendship < Relationship
    class << self
      def bucket_name
        "egotter.#{Rails.env}.mutual-friendships"
      end
    end
  end
end
