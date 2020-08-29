# -*- SkipSchemaAnnotations

module S3
  class FavoriteFriendship < Relationship
    class << self
      def bucket_name
        "egotter.#{Rails.env}.favorite-friendships"
      end
    end
  end
end
