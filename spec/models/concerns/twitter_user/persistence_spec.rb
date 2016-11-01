require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Persistence do
  subject(:tu) { build(:twitter_user) }

  describe '#put_relations_back' do
    it 'calls #import_relations!' do
      tu.instance_variable_set(:@shaded, {friends: []})
      expect(TwitterUser).to receive(:import_relations!)
      tu.send(:put_relations_back)
    end

    context '#import_relations! raises an exception' do
      before do
        allow(TwitterUser).to receive(:import_relations!).and_raise('import failed')
      end
      it 'calls #destroy' do
        tu.instance_variable_set(:@shaded, {friends: []})
        expect(tu).to receive(:destroy)
        tu.send(:put_relations_back)
      end
    end
  end

  describe '#save' do
    context 'it is new record' do
      it 'calls #push_relations_aside and #put_relations_back' do
        expect(tu).to receive(:push_relations_aside)
        expect(tu).to receive(:put_relations_back)
        expect(tu.save).to be_truthy
      end
    end

    context 'it is already persisted' do
      before { tu.save! }
      it 'does not call #push_relations_aside and #put_relations_back' do
        tu.uid = tu.uid.to_i * 2
        expect(tu).not_to receive(:push_relations_aside)
        expect(tu).not_to receive(:put_relations_back)
        expect(tu.save).to be_truthy
      end
    end
  end

  describe '#import_relations!' do
    let(:followers) { [build(:follower)] }
    before { tu.save! }

    it 'does not call Follower#valid?' do
      followers.each { |f| expect(f).not_to receive(:valid?) }
      expect { TwitterUser.import_relations!(tu.id, :followers, followers) }.to change { Follower.all.size }.by(1)
    end

    context 'with invalid followers' do
      before { followers.each { |f| f.uid = -100 } }
      it 'saves followers' do
        expect { TwitterUser.import_relations!(tu.id, :followers, followers) }.to change { Follower.all.size }.by(1)
      end
    end

    context 'Follower.import raises an exception' do
      before { allow(Follower).to receive(:import).and_raise('import failed') }

      it 'raises an exception' do
        expect { TwitterUser.import_relations!(tu.id, :followers, followers) }.to raise_error(RuntimeError, 'import failed')
      end
    end
  end
end
