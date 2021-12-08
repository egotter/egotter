Rails.application.reloader.to_prepare do
  ApiClient::RequestWithRetryHandler.prepend(Module.new do
    %i(
        perform
      ).each do |method_name|
      define_method(method_name) do |*args, &blk|
        Airbag.benchmark("Benchmark #{self.class}##{method_name} name=#{@method}", level: :debug) do
          method(method_name).super_method.call(*args, &blk)
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

  Efs::Client.prepend(Module.new do
    %i(
        read
        write
        delete
      ).each do |method_name|
      define_method(method_name) do |*args, &blk|
        Airbag.benchmark("Benchmark #{self.class}##{method_name} for #{@klass} #{@dir}/#{args[0]}", level: :debug) do
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
      define_method(method_name) do |*args, &blk|
        Airbag.benchmark("Benchmark #{self}##{method_name} twitter_user_id=#{args[0][:twitter_user_id]}", slow_duration: 300) do
          method(method_name).super_method.call(*args, &blk)
        end
      end
    end
  end)

  S3::Followership.singleton_class.prepend(Module.new do
    %i(
        find_by
      ).each do |method_name|
      define_method(method_name) do |*args, &blk|
        Airbag.benchmark("Benchmark #{self}##{method_name} twitter_user_id=#{args[0][:twitter_user_id]}", slow_duration: 300) do
          method(method_name).super_method.call(*args, &blk)
        end
      end
    end
  end)

  SearchRequestValidator.prepend(Module.new do
    %i(
        blocked_user?
        timeline_readable?
      ).each do |method_name|
      define_method(method_name) do |*args, &blk|
        Airbag.benchmark("Benchmark #{self.class}##{method_name} screen_name=#{args[0]}", slow_duration: 50) do
          method(method_name).super_method.call(*args, &blk)
        end
      end
    end
  end)
end
