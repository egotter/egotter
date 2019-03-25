require 'rails_helper'

RSpec.describe S3::Cache do
  let(:dummy_class) do
    Class.new do
      extend S3::Cache
    end
  end

  describe '.cache_fetch' do
    let(:key) { 'key' }
    let(:result) { 'result' }
    let(:block) do
      @count = 0
      proc do
        if @count == 0
          @count += 1
          raise err
        end
        result
      end
    end

    let(:endless_block) do
      proc {raise err}
    end

    subject { dummy_class.cache_fetch(key, &block) }

    context 'With Errno::ENOENT' do
      let(:err) { Errno::ENOENT }
      it {is_expected.to eq(result)}
    end

    context 'With Errno::ESTALE' do
      let(:err) { Errno::ESTALE }
      it {is_expected.to eq(result)}
    end

    context 'With Zlib::DataError' do
      let(:err) { Zlib::DataError }
      it {is_expected.to eq(result)}
    end

    context 'With endless error' do
      let(:err) { Errno::ENOENT.new('dir') }

      before do
        dummy_class.send(:extend, S3::Util) # For logger
      end
      it do
        expect { dummy_class.cache_fetch(key, &endless_block) }.to raise_error('No such file or directory - dir')
      end
    end
  end
end
