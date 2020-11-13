require 'rails_helper'

RSpec.describe ReportErrorHandler do
  let(:instance) { double('instance') }

  before do
    instance.extend ReportErrorHandler
  end

  describe '#ignorable_report_error?' do
    let(:error) { RuntimeError.new('error') }
    subject { instance.ignorable_report_error?(error) }

    %i(
        unauthorized?
        invalid_or_expired_token?
    ).each do |method|
      context "#{method} returns true" do
        before { allow(TwitterApiStatus).to receive(method).with(error).and_return(true) }
        it { is_expected.to be_truthy }
      end
    end

    %i(
        your_account_suspended?
        protect_out_users_from_spam?
        might_be_automated?
        you_have_blocked?
        not_allowed_to_access_or_delete?
        cannot_send_messages?
        cannot_find_specified_user?
        not_following_you?
    ).each do |method|
      context "#{method} returns true" do
        before { allow(DirectMessageStatus).to receive(method).with(error).and_return(true) }
        it { is_expected.to be_truthy }
      end
    end

    context "unknown exception is raised" do
      it { is_expected.to be_falsey }
    end
  end
end
