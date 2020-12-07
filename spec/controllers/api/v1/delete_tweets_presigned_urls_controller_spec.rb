require 'rails_helper'

RSpec.describe Api::V1::DeleteTweetsPresignedUrlsController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(user).to receive(:has_valid_subscription?).and_return(true)
  end

  describe 'POST #create' do
    let(:filename) { 'twitter-2000-00-00-abcde.zip' }
    let(:filesize) { 1.gigabytes }
    subject { post :create, params: {filename: filename, filesize: filesize} }
    before { allow(S3::ArchiveData).to receive(:presigned_url).with(user.uid, filename, filesize.to_s) }
    it { is_expected.to have_http_status(:ok) }
  end
end
