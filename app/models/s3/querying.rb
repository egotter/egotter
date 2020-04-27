# -*- SkipSchemaAnnotations
module S3
  module Querying
    def find_by_current_scope!(payload_key, key_attr, key_value)
      text = fetch(key_value)
      item = parse_json(text)
      payload = item.has_key?('compress') ? unpack(item[payload_key.to_s]) : item[payload_key.to_s]
      values = {
          key_attr.to_sym => item[key_attr.to_s],
          screen_name: item['screen_name'],
          payload_key.to_sym => payload
      }

      unless key_attr.to_sym == :uid
        values[:uid] = item['uid']
      end

      values
    end

    def find_by_current_scope(payload_key, key_attr, key_value)
      find_by_current_scope!(payload_key, key_attr, key_value)
    rescue Aws::S3::Errors::NoSuchKey => e
      logger.info "#{self}##{__method__} Return empty hash. #{e.message} #{payload_key} #{key_attr} #{key_value}"
      logger.debug {e.backtrace.join("\n")}
      {}
    rescue => e
      logger.warn "#{self}##{__method__} #{e.class} #{e.message} #{payload_key} #{key_attr} #{key_value}"
      logger.info {e.backtrace.join("\n")}
      {}
    end
  end
end
