require 'rails_helper'

RSpec.describe Api::BaseController, type: :controller do
  controller Api::BaseController do
    def summary_uids
    end

    def list_uids
    end
  end

  describe 'GET #summary' do
    subject { controller.summary }
    it do
      expect(controller).to receive(:summary_uids).and_return([[], 0])
      expect(controller).to receive(:render).with(json: {name: 'base', count: 0, users: []})
      subject
    end
  end

  describe 'GET #list' do
    subject { controller.list }
    it do
      expect(controller).to receive(:list_uids).and_return([])
      expect(controller).to receive(:render).with(json: {name: 'base', max_sequence: -1, limit: 0, users: []})
      subject
    end

    [
        TwitterDB::Sort::TooManySortTargets,
    ].each do |error_class|
      context "#{error_class} is raised" do
        let(:error) { error_class.new }
        before { allow(TwitterDB::Proxy).to receive(:new).with(anything).and_raise(error) }
        it do
          expect(controller).to receive(:render).with(json: {name: 'base', message: instance_of(String)}, status: :bad_request)
          subject
        end
      end
    end

    [
        TwitterDB::Sort::SafeTimeout,
        TwitterDB::Sort::CreatingCache,
        TwitterDB::Sort::CreatingCacheStarted,
        TwitterDB::Sort::AlreadyCreatingCache,
    ].each do |error_class|
      context "#{error_class} is raised" do
        let(:error) { error_class.new }
        before { allow(TwitterDB::Proxy).to receive(:new).with(anything).and_raise(error) }
        it do
          expect(controller).to receive(:render).with(json: {name: 'base', message: instance_of(String)}, status: :request_timeout)
          subject
        end
      end
    end
  end
end
