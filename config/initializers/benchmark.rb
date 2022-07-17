Rails.application.reloader.to_prepare do
  TwitterRequest.prepend(Module.new do
    %i(
        perform
      ).each do |method_name|
      define_method(method_name) do |*args, **kwargs, &blk|
        Airbag.benchmark("Benchmark #{self.class}##{method_name} name=#{@method}", level: :debug) do
          method(method_name).super_method.call(*args, **kwargs, &blk)
        end
      end
    end
  end)

  InMemory::TwitterUser.singleton_class.prepend(Module.new do
    %i(
        find_by
      ).each do |method_name|
      define_method(method_name) do |*args, &blk|
        Airbag.benchmark("Benchmark #{self}##{method_name} twitter_user_id=#{args[0]}") do
          method(method_name).super_method.call(*args, &blk)
        end
      end
    end
  end)

  Efs::TwitterUser.singleton_class.prepend(Module.new do
    %i(
        find_by
      ).each do |method_name|
      define_method(method_name) do |*args, &blk|
        Airbag.benchmark("Benchmark #{self}##{method_name} twitter_user_id=#{args[0]}") do
          method(method_name).super_method.call(*args, &blk)
        end
      end
    end
  end)

  S3::Friendship.singleton_class.prepend(Module.new do
    %i(
        find_by
      ).each do |method_name|
      define_method(method_name) do |**kwargs, &blk|
        Airbag.benchmark("Benchmark #{self}##{method_name} twitter_user_id=#{kwargs[:twitter_user_id]}") do
          method(method_name).super_method.call(**kwargs, &blk)
        end
      end
    end
  end)

  S3::Followership.singleton_class.prepend(Module.new do
    %i(
        find_by
      ).each do |method_name|
      define_method(method_name) do |**kwargs, &blk|
        Airbag.benchmark("Benchmark #{self}##{method_name} twitter_user_id=#{kwargs[:twitter_user_id]}") do
          method(method_name).super_method.call(**kwargs, &blk)
        end
      end
    end
  end)
end
