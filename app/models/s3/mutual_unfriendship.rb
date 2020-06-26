# -*- SkipSchemaAnnotations

module S3
  class MutualUnfriendship < Relationship
    class << self
      def bucket_name
        "egotter.#{Rails.env}.mutual-unfriendships"
      end
    end
  end
end
