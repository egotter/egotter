require 'rails_helper'

RSpec.describe S3 do
  let(:dummy_class) do
    Class.new do
      extend S3::Util

      self.bucket_name = "egotter.#{Rails.env}.hello"
    end
  end

  describe '.cache' do
    context 'cache_enabled? == true' do
      before { allow(dummy_class).to receive(:cache_enabled?).and_return(true) }

      context '@cache is defined' do
        before { dummy_class.instance_variable_set(:@cache, 'Hello') }
        it do
          expect(dummy_class.cache).to eq('Hello')
        end
      end

      context '@cache is NOT defined' do
        it do
          expect(dummy_class.cache).to a_kind_of(ActiveSupport::Cache::FileStore)
        end
      end
    end

    context 'cache_enabled? == false' do
      before { allow(dummy_class).to receive(:cache_enabled?).and_return(false) }

      it do
        expect(dummy_class.cache).to a_kind_of(ActiveSupport::Cache::NullStore)
      end
    end
  end

  describe '.cache_enabled?' do
  end

  describe '.cache_enabled=' do
  end

  describe '.cache_disabled' do
    before { dummy_class.instance_variable_set(:@cache_enabled, true) }
    it do
      dummy_class.cache_disabled do
        expect(dummy_class.instance_variable_get(:@cache_enabled)).to be_falsey
      end
      expect(dummy_class.instance_variable_get(:@cache_enabled)).to be_truthy
    end
  end

  describe '.delete_cache' do
  end
end
