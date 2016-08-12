module KpiAdmin
  class Engine < ::Rails::Engine
    isolate_namespace KpiAdmin

    def self.use(*args)
      if block_given?
        middleware.use(*args, &Proc.new)
      else
        middleware.use(*args)
      end
    end
  end
end
