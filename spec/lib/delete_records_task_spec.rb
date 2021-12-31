require 'rails_helper'

RSpec.describe DeleteRecordsTask, type: :model do
  let(:year) { '2021' }
  let(:month) { '01' }
  let(:instance) { described_class.new(klass, year, month) }

  describe '#start' do
    subject { instance.start }

    context 'SearchLog is specified' do
      let(:klass) { SearchLog }
      before { create(:search_log, created_at: '2021-01-10') }
      it { expect { subject }.to change { klass.all.size }.by(-1) }
    end

    context 'CrawlerLog is specified' do
      let(:klass) { CrawlerLog }
      before { create(:crawler_log, created_at: '2021-01-10') }
      it { expect { subject }.to change { klass.all.size }.by(-1) }
    end

    context 'Ahoy::Visit is specified' do
      let(:klass) { Ahoy::Visit }
      before { create(:ahoy_visit, started_at: '2021-01-10') }
      it { expect { subject }.to change { klass.all.size }.by(-1) }
    end

    context 'Ahoy::Event is specified' do
      let(:klass) { Ahoy::Event }
      before { build(:ahoy_event, time: '2021-01-10').save(validate: false) }
      it { expect { subject }.to change { klass.all.size }.by(-1) }
    end
  end
end
