require 'rails_helper'

RSpec.describe CloseFriendsOgImage, type: :model do
  let(:instance) { described_class.create(uid: 1) }

  describe '#fresh?' do
    subject { instance.fresh? }
    it { is_expected.to be_truthy }
  end
end

RSpec.describe CloseFriendsOgImage::Generator, type: :model do
  describe '#generate' do

  end

  describe '.outfile_path' do
    let(:uid) { 123 }
    subject { described_class.outfile_path(uid) }
    it do
      is_expected.to satisfy do |result|
        result = result.to_s
        expect(result).to include(uid.to_s)
        expect(result).to include(Process.pid.to_s)
        expect(result).to include(Thread.current.object_id.to_s(36))
      end
    end
  end

  describe '.generate_heart_image' do
    let(:uid) { 123 }
    let(:users) { [{screen_name: 'name', profile_image_url_https: 'https://example.com/profile.jpg'}] }
    subject { described_class.generate_heart_image(uid, users) }
    after do
      CloseFriendsOgImage::ImagesLoader.cleanup(uid)
    end
    it do
      is_expected.to satisfy do |result|
        expect(result).not_to match(/screen_name_\d+/)
        expect(result).not_to match(/image_url_\d+/)
      end
    end
  end

  describe '.generate_image' do

  end
end

RSpec.describe CloseFriendsOgImage::ImagesLoader, type: :model do
  let(:uid) { 1 }
  let(:urls) { ['url1', 'url2'] }
  let(:instance) { described_class.new(uid, urls) }

  describe '#load' do
    subject { instance.load }
    it do
      urls.each.with_index do |url, i|
        expect(instance).to receive(:url2base64).with(url).and_return("path#{i}")
      end
      subject
    end
  end

  # describe '.cleanup' do
  #   subject { described_class.cleanup(uid) }
  #   before do
  #     path = "#{described_class.new(uid, nil).send(:dir_path)}/empty_file"
  #     system("touch #{path}")
  #   end
  #   it { is_expected.to be_truthy }
  # end

  describe '#url2file' do
    let(:url) { 'url' }
    let(:filepath) { Rails.root.join('tmp/file') }
    subject { instance.send(:url2file, url) }
    before do
      allow(instance).to receive(:file_path).with(url).and_return(filepath)
    end
    after do
      File.delete(filepath) if File.exist?(filepath)
    end
    it do
      expect(instance).to receive(:open_url).with(url).and_return('image')
      is_expected.to eq(filepath)
      expect(File.read(filepath)).to eq('image')
    end
  end
end
