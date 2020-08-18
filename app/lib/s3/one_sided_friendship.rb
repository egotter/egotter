# -*- SkipSchemaAnnotations

module S3
  class OneSidedFriendship < Relationship
    class << self
      def bucket_name
        "egotter.#{Rails.env}.one-sided-friendships"
      end
    end
  end
end
