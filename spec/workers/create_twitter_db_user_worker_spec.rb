require 'rails_helper'

RSpec.describe CreateTwitterDBUserWorker do
  let(:bot) { create(:bot) }
  let(:client) { bot.api_client }
  let(:user) { create(:user) }
  let(:uids) { [1, 2] }
  let(:worker) { CreateTwitterDBUserWorker.new }

  describe '#perform' do
    subject { worker.perform(uids, options) }

    context 'The options includes only force_update' do
      let(:options) { {'force_update' => true} }
      it do
        expect(User).not_to receive(:find)
        expect(Bot).to receive(:api_client).with(no_args).and_return(client)
        expect(worker).to receive(:do_perform).with(uids, client, true, nil, enqueued_by: nil)
        subject
      end
    end

    context 'The options includes only user_id' do
      context 'user_id != -1' do
        let(:options) { {'user_id' => user.id} }
        it do
          expect(User).to receive(:find).with(user.id).and_return(user)
          expect(user).to receive(:api_client).with(no_args).and_return(client)
          expect(Bot).not_to receive(:api_client)
          expect(worker).to receive(:do_perform).with(uids, client, nil, user.id, enqueued_by: nil)
          subject
        end

        context 'The user is not authorized' do
          before { allow(user).to receive(:authorized?).with(no_args).and_return(false) }
          it do
            expect(User).to receive(:find).with(user.id).and_return(user)
            expect(user).not_to receive(:api_client)
            expect(Bot).to receive(:api_client).with(no_args).and_return(client)
            expect(worker).to receive(:do_perform).with(uids, client, nil, user.id, enqueued_by: nil)
            subject
          end
        end
      end

      context 'user_id == -1' do
        let(:options) { {'user_id' => -1} }
        it do
          expect(User).not_to receive(:find)
          expect(Bot).to receive(:api_client).with(no_args).and_return(client)
          expect(worker).to receive(:do_perform).with(uids, client, nil, -1, enqueued_by: nil)
          subject
        end
      end
    end

    context "The options is empty" do
      let(:options) { {} }
      it do
        expect(User).not_to receive(:find)
        expect(Bot).to receive(:api_client).and_return(client)
        expect(worker).to receive(:do_perform).with(uids, client, nil, nil, enqueued_by: nil)
        subject
      end
    end
  end

  describe '#do_perform' do
    subject { worker.do_perform(uids, nil, false, user_id, enqueued_by: nil) }

    before do
      allow(TwitterDB::User::Batch).to receive(:fetch_and_import!).with(any_args).and_raise(exception)
    end

    context 'An exception is raised' do
      let(:user_id) { user.id }
      let(:exception) { RuntimeError.new('Something happened.') }

      it do
        expect(Bot).not_to receive(:api_client)
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'Twitter::Error::Unauthorized is raised and the valid user_id is passed' do
      let(:user_id) { user.id }
      let(:exception) { Twitter::Error::Unauthorized.new('Invalid or expired token.') }

      it do
        expect(Bot).to receive(:api_client).with(no_args)
        expect { subject }.to raise_error(Twitter::Error::Unauthorized)
      end
    end

    context 'Twitter::Error::Forbidden is raised and the valid user_id is passed' do
      let(:user_id) { user.id }
      let(:exception) { Twitter::Error::Forbidden.new('Message') }

      it do
        expect(Bot).to receive(:api_client).with(no_args)
        expect { subject }.to raise_error(Twitter::Error::Forbidden)
      end
    end

    context 'A retryable exception is raised and the user_id is nil' do
      let(:user_id) { nil }
      let(:exception) { Twitter::Error::Unauthorized.new('Invalid or expired token.') }

      it do
        expect(Bot).not_to receive(:api_client)
        expect { subject }.to raise_error(Twitter::Error::Unauthorized)
      end
    end
  end
end
