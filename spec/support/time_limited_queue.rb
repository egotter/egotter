shared_examples_for 'Time limited queue' do
  class AnyClass
  end

  describe '#initialize' do
    context 'With implicit ttl (the default ttl is 10.minutes)' do
      let(:instance) { described_class.new(AnyClass) }

      it do
        expect(instance.instance_variable_get(:@key)).to eq("#{described_class}:#{AnyClass}:any_ids")
      end

      it do
        expect(instance.instance_variable_get(:@ttl)).to eq(10.minutes)
      end

      it 'expires the key after the implicit ttl has passed' do
        key = 1
        instance.add(key)
        expect(instance.exists?(key)).to be_truthy

        travel (1.second) do
          expect(instance.exists?(key)).to be_truthy
        end

        travel (1.hour) do
          expect(instance.exists?(key)).to be_falsey
        end
      end
    end

    context 'With specified ttl' do
      let(:ttl) { 10.seconds }
      let(:instance) { described_class.new(AnyClass, ttl) }

      it do
        expect(instance.instance_variable_get(:@key)).to eq("#{described_class}:#{AnyClass}:#{ttl}:any_ids")
      end

      it do
        expect(instance.instance_variable_get(:@ttl)).to eq(ttl)
      end

      it 'expires the key after the specified ttl has passed' do
        key = 1
        instance.add(key)
        expect(instance.exists?(key)).to be_truthy

        travel (ttl - 1.second) do
          expect(instance.exists?(key)).to be_truthy
        end

        travel (ttl + 1.second) do
          expect(instance.exists?(key)).to be_falsey
        end
      end
    end
  end
end
