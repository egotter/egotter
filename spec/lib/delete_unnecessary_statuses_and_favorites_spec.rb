require 'rails_helper'

RSpec.describe DeleteUnnecessaryStatusesAndFavorites do
  let(:uid) { 1 }

  describe '#run' do
    context 'There are 2 records have same uid' do
      before do
        create_records(2)
      end

      it "doesn't delete statuses" do
        expect { DeleteUnnecessaryStatusesAndFavorites.new.run }.to_not change { Status.all.size }
      end

      it "doesn't delete favorites" do
        expect { DeleteUnnecessaryStatusesAndFavorites.new.run }.to_not change { Favorite.all.size }
      end
    end

    context 'There are 3 records have same uid' do
      before do
        create_records(3)
      end

      it 'deletes statuses' do
        expect { DeleteUnnecessaryStatusesAndFavorites.new.run }.to change { Status.all.size }
      end

      it 'deletes favorites' do
        expect { DeleteUnnecessaryStatusesAndFavorites.new.run }.to change { Favorite.all.size }
      end

      it "doesn't delete statuses related to latest TwitterUser" do
        expect { DeleteUnnecessaryStatusesAndFavorites.new.run }.to_not change { TwitterUser.order(created_at: :desc).first.statuses.size }
      end

      it "doesn't delete favorites related to latest TwitterUser" do
        expect { DeleteUnnecessaryStatusesAndFavorites.new.run }.to_not change { TwitterUser.order(created_at: :desc).first.favorites.size }
      end
    end
  end
end

def create_records(num)
  num.times do
    build(:twitter_user, uid: uid).save_with_bulk_insert
  end
  raise if TwitterUser.all.size != num
  raise unless Status.all.any?
  raise unless Favorite.all.any?
end