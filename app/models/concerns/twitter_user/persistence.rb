require 'active_support/concern'

module Concerns::TwitterUser::Persistence
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def save(*args)
    if persisted?
      return super(*args)
    end

    if invalid?
      logger.info "#{self.class}##{__method__}: #{errors.full_messages}"
      return false
    end

    # Fetch before calling save, or `SELECT * FROM relation_name WHERE from_id = xxx` is executed.
    relations = %i(friends followers statuses mentions search_results favorites).map do |attr|
      [attr, send(attr).to_a.dup]
    end.to_h

    relations.keys.each do |attr|
      send("#{attr}=", [])
    end

    return false unless super(validate: false)

    relations.each { |attr, values| import_relations!(attr, values) }
    reload
    true
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    destroy
    false
  end

  private

  def import_relations!(attr, values)
    klass = attr.to_s.classify.constantize
    benchmark_and_silence(attr) do
      values.each { |v| v.from_id = id }
      ActiveRecord::Base.transaction do
        values.each_slice(1000).each { |ary| klass.import(ary, validate: false) }
      end
    end
  end

  def benchmark_and_silence(attr)
    ActiveRecord::Base.benchmark("#{self.class}#save #{attr}") do
      logger.silence do
        yield
      end
    end
  end
end
