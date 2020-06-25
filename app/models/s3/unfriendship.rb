# -*- SkipSchemaAnnotations

module S3
  class Unfriendship < Relationship
    class << self
      def bucket_name
        "egotter.#{Rails.env}.unfriendships"
      end
    end
  end
end
