require 'rails_helper'

RSpec.describe CloseFriendsOgImage, type: :model do
end

RSpec.describe CloseFriendsOgImage::Generator, type: :model do
  describe '.outfile_path' do
    let(:uid) { 123 }
    subject { described_class.outfile_path(uid) }
    it do
      is_expected.to satisfy do |result|
        expect(result).to include(uid.to_s)
        expect(result).to include(Process.pid.to_s)
        expect(result).to include(Thread.current.object_id.to_s(36))
      end
    end
  end

  describe '.generate_heart_image' do
    let(:users) { [{screen_name: 'name', profile_image_url_https: 'https://example.com/profile.jpg'}] }
    subject { described_class.generate_heart_image(users) }
    it do
      is_expected.to satisfy do |result|
        expect(result).not_to match(/screen_name_\d+/)
        expect(result).not_to match(/image_url_\d+/)
      end
    end
  end
end
