# -*- SkipSchemaAnnotations

module S3
  class OneSidedFollowership < Relationship
    class << self
      def bucket_name
        "egotter.#{Rails.env}.one-sided-followerships"
      end
    end
  end
end
