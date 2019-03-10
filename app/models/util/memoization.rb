module Util
  module Memoization
    def valid_ivar_name(str)
      str.match(/[\w_]+/)[0]
    end

    MEMOIZE_PREFIX = 'memoize_'

    def memoize(method_name = nil)
      method_name = @@method_added unless method_name
      return if method_name.to_s.start_with? MEMOIZE_PREFIX

      alias_method "#{MEMOIZE_PREFIX}#{method_name}", method_name
      define_method(method_name) do |*args|
        ivar_name = "@#{self.class.valid_ivar_name(method_name)}"
        if instance_variable_defined?(ivar_name)
          instance_variable_get(ivar_name)
        else
          instance_variable_set(ivar_name, send("#{MEMOIZE_PREFIX}#{method_name}", *args))
        end
      end
    end

    def method_added(name)
      @@method_added = name
    end
  end
end
