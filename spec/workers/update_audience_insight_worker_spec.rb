require 'rails_helper'

RSpec.describe UpdateAudienceInsightWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:options) { {} }
    let(:twitter_user) { create(:twitter_user) }
    let(:insight_attrs) do
      {
          categories_text: ['2020-10-01'].to_json,
          friends_text: {name: 'aaa', data: [1, 2]}.to_json,
          followers_text: {name: 'bbb', data: [1, 2]}.to_json,
          new_friends_text: {name: 'ccc', data: [1, 2]}.to_json,
          new_followers_text: {name: 'ddd', data: [1, 2]}.to_json,
      }
    end
    subject { worker.perform(twitter_user.uid, options) }

    before do
      allow(AudienceInsight::Builder).to receive_message_chain(:new, :build).
          with(twitter_user.uid, anything).with(no_args).and_return(insight_attrs)
    end

    it do
      expect(worker).not_to receive(:handle_exception)
      is_expected.to be_truthy
    end

    context 'An exception is raised' do
      let(:error) { RuntimeError }
      before { allow(AudienceInsight).to receive(:find_or_initialize_by).with(any_args).and_raise(error) }

      it do
        expect(worker).to receive(:handle_exception).with(error, twitter_user.uid, options)
        subject
      end
    end
  end
end
