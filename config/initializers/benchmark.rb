Rails.application.reloader.to_prepare do
  S3::Friendship.singleton_class.prepend(Module.new do
    %i(
        find_by
      ).each do |method_name|
      define_method(method_name) do |*args, &blk|
        ApplicationRecord.benchmark("Benchmark #{self}##{method_name} twitter_user_id=#{args[0][:twitter_user_id]}") do
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
        ApplicationRecord.benchmark("Benchmark #{self}##{method_name} twitter_user_id=#{args[0][:twitter_user_id]}") do
          method(method_name).super_method.call(*args, &blk)
        end
      end
    end
  end)
end
