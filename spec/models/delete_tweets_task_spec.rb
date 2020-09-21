require 'rails_helper'

RSpec.describe DeleteTweetsTask, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:delete_tweets_request, user_id: user.id) }
  let(:task) { described_class.new(request) }

  describe '#start!' do
    subject { task.start! }

    it do
      expect(SendDeleteTweetsNotFinishedWorker).to receive(:perform_in).with(30.minutes, request.id, {})
      expect(task).to receive(:perform_request!).with(request)
      subject
    end

    context 'The request has already been finished' do
      before { allow(request).to receive(:finished?).and_return(true) }
      it do
        expect(request).to receive(:update).with(error_class: described_class::AlreadyFinished)
        expect(SendDeleteTweetsNotFinishedWorker).not_to receive(:perform_in)
        expect(task).not_to receive(:perform_request!)
        subject
      end
    end
  end

  describe '#perform_request!' do
    subject { task.send(:perform_request!, request) }

    it do
      expect(request).to receive(:perform!)
      subject
    end

    context 'TweetsNotFound is raised' do
      before { allow(request).to receive(:perform!).and_raise(DeleteTweetsRequest::TweetsNotFound) }
      it do
        expect(request).to receive(:finished!)
        subject
      end
    end

    context 'RetryableError is raised' do
      let(:error) { DeleteTweetsRequest::RetryableError.new(retry_in: 1, destroy_count: 2) }
      before { allow(request).to receive(:perform!).and_raise(error) }
      it do
        expect(DeleteTweetsWorker).to receive(:perform_in).with(1, request.id, {})
        expect(request).to receive(:update).with(error_class: error.class, error_message: error.message)
        subject
      end
    end

    context 'Error is raised' do
      let(:error) { RuntimeError.new('error') }
      before { allow(request).to receive(:perform!).and_raise(error) }
      it do
        expect(request).to receive(:send_error_message)
        expect(request).to receive(:update).with(error_class: error.class, error_message: error.message)
        expect { subject }.to raise_error(error)
      end
    end
  end
end
