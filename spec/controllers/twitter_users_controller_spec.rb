require 'rails_helper'

RSpec.describe TwitterUsersController, type: :controller do
  describe '#changes_text' do
    let(:previous_friends) { 1 }
    let(:current_friends) { 1 }
    let(:previous_followers) { 1 }
    let(:current_followers) { 1 }
    let(:previous_version) { double('twitter_user', id: 1, uid: 3, screen_name: 'name', friends_count: previous_friends, followers_count: previous_followers) }
    let(:twitter_user) { double('twitter_user', id: 2, uid: 3, screen_name: 'name', friends_count: current_friends, followers_count: current_followers) }
    let(:uids) { [] }
    subject { controller.send(:changes_text, twitter_user) }

    before do
      allow(twitter_user).to receive(:previous_version).and_return(previous_version)
      allow(twitter_user).to receive(:calc_new_unfollower_uids).and_return(uids)
    end

    context 'previous_version is nil' do
      let(:previous_version) { nil }
      it { is_expected.to be_truthy }
    end

    context 'uids is not empty' do
      let(:uids) { [1] }
      it { is_expected.to be_truthy }
    end

    context 'followers increased' do
      let(:previous_followers) { 1 }
      let(:current_followers) { 2 }
      it { is_expected.to be_truthy }
    end

    context 'followers decreased' do
      let(:previous_followers) { 2 }
      let(:current_followers) { 1 }
      it { is_expected.to be_truthy }
    end

    context 'friends increased' do
      let(:previous_friends) { 1 }
      let(:current_friends) { 2 }
      it { is_expected.to be_truthy }
    end

    context 'friends decreased' do
      let(:previous_friends) { 2 }
      let(:current_friends) { 1 }
      it { is_expected.to be_truthy }
    end

    context 'both friends and followers not changed' do
      let(:previous_friends) { 1 }
      let(:current_friends) { 1 }
      let(:previous_followers) { 1 }
      let(:current_followers) { 1 }
      it { is_expected.to be_truthy }
    end

    context 'error is raised' do
      before { allow(twitter_user).to receive(:previous_version).and_raise('error') }
      it { is_expected.to be_truthy }
    end
  end
end
