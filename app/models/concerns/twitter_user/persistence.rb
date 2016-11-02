require 'active_support/concern'
module Concerns::TwitterUser::Persistence
  extend ActiveSupport::Concern

  class_methods do
    def import_relations!(id, attr, values)
      klass = attr.to_s.classify.constantize
      benchmark_and_silence(attr) do
        values.each { |v| v.from_id = id }
        ActiveRecord::Base.transaction do
          values.each_slice(1000).each { |ary| klass.import(ary, validate: false) }
        end
      end
    end

    def benchmark_and_silence(attr)
      ActiveRecord::Base.benchmark("#{self.class}#import_relations! #{attr}") do
        logger.silence do
          yield
        end
      end
    end
  end

  included do
    before_create :push_relations_aside

    # With transactional_fixtures = true, after_commit callbacks is not fired.
    if Rails.env.test?
      after_create :put_relations_back
    else
      after_commit :put_relations_back, on: :create
    end
  end

  private

  def push_relations_aside
    # Fetch before calling save, or `SELECT * FROM relation_name WHERE from_id = xxx` is executed
    # even if `auto_save: false` is specified.
    @shaded = %i(friends followers statuses mentions search_results favorites).map { |attr| [attr, send(attr).to_a.dup] }.to_h
    @shaded.keys.each { |attr| send("#{attr}=", []) }
  end

  def put_relations_back
    # Relations are created on `after_commit` in order to avoid long trunsaction.
    @shaded.each { |attr, values| self.class.import_relations!(self.id, attr, values) }
    remove_instance_variable(:@shaded)
    reload
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{self.inspect}"
    destroy
  end
end
