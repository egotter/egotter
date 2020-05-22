# -*- SkipSchemaAnnotations

module S3
  class InactiveFollowership < Relationship
    class << self
      def bucket_name
        "egotter.#{Rails.env}.inactive-followerships"
      end
    end
  end
end
