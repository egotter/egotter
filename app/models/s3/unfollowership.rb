# -*- SkipSchemaAnnotations

module S3
  class Unfollowership < Relationship
    class << self
      def bucket_name
        "egotter.#{Rails.env}.unfollowerships"
      end
    end
  end
end
