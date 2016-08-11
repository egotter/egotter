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

    relations = %i(friends followers statuses mentions search_results favorites).map do |name|
      [name, send(name).to_a.dup]
    end.to_h

    relations.keys.each do |name|
      send("#{name}=", [])
    end

    return false unless super(validate: false)

    begin
      relations.each { |name, values| import_relations!(name, values) }
      reload
    rescue => e
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
      destroy
      false
    else
      true
    end
  end

  private

  def import_relations!(name, values)
    klass = name.to_s.classify.constantize
    benchmark_and_silence(name) do
      values.each { |v| v.from_id = id }
      ActiveRecord::Base.transaction do
        values.each_slice(100).each { |v| klass.import(v, validate: false) }
      end
    end
  end

  def benchmark_and_silence(message)
    ActiveRecord::Base.benchmark("#{self.class}#save #{message}") do
      logger.silence do
        yield
      end
    end
  end
end