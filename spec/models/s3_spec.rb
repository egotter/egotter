require 'rails_helper'

RSpec.describe S3 do
  let(:dummy_class) do
    Class.new do
      extend S3::Util

      self.bucket_name = "egotter.#{Rails.env}.hello"
    end
  end
end
