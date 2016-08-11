require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Persistence do
  subject(:tu) { build(:twitter_user) }

  describe '#save' do
    it 'returns true' do
      expect(tu.save).to be_truthy
    end

    context 'it is already persisted' do
      before { tu.save! }
      it 'does not call #import_relations!' do
        tu.uid = tu.uid.to_i * 2
        expect(tu).not_to receive(:import_relations!)
        expect(tu.save).to be_truthy
      end
    end

    context '#import_relations! raises an exception' do
      before { allow(tu).to receive(:import_relations!).and_raise('import failed') }
      it 'saves nothing' do
        expect(tu.save).to be_falsey
        expect(tu.destroyed?).to be_truthy
        expect(tu.friends).to be_empty
        expect(tu.followers).to be_empty
      end
    end

    context '#invalid? returns true' do
      before { allow(tu).to receive(:invalid?).and_return(true) }
      it 'saves nothing' do
        expect(tu.save).to be_falsey
        expect(tu.persisted?).to be_falsey
      end
    end
  end

  describe '#import_relations!' do
    let(:follower) { build(:follower) }
    before { tu.save! }

    it 'does not call Follower#valid?' do
      expect_any_instance_of(Follower).not_to receive(:valid?)
      expect { tu.send(:import_relations!, :followers, [follower]) }.to change { Follower.all.size }.by(1)
    end

    context 'with invalid followers' do
      before { follower.uid = -100 }
      it 'saves followers' do
        expect { tu.send(:import_relations!, :followers, [follower]) }.to change { Follower.all.size }.by(1)
      end
    end

    context 'Follower.import raises an exception' do
      before { allow(Follower).to receive(:import).and_raise('import failed') }

      it 'raises an exception' do
        expect { tu.send(:import_relations!, :followers, [follower]) }.to raise_error(RuntimeError, 'import failed')
      end
    end
  end
end