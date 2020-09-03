require 'rails_helper'

RSpec.describe CloseFriendsOgImage, type: :model do
end

RSpec.describe CloseFriendsOgImage::Generator, type: :model do
  describe '.generate_heart_image' do
    let(:users) { [double('User', screen_name: 'name1', profile_image_url_https: 'https://example.com/profile.jpg')] }
    subject { described_class.generate_heart_image(users) }
    it do
      result = subject
      expect(result.match?(/screen_name_\d+/)).to be_falsey
      expect(result.match?(/image_url_\d+/)).to be_falsey
    end
  end
end
