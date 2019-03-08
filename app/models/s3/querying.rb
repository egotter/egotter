# -*- SkipSchemaAnnotations
module S3
  module Querying
    def find_by_current_scope!(payload_key, key_attr, key_value)
      text = fetch(key_value)
      item = parse_json(text)
      payload = item.has_key?('compress') ? unpack(item[payload_key.to_s]) : item[payload_key.to_s]
      values = {
          key_attr.to_sym => item[key_value.to_s],
          screen_name: item['screen_name'],
          payload_key.to_sym => payload
      }

      unless key_attr.to_sym == :uid
        values[:uid] = item['uid']
      end

      values
    end

    def find_by_current_scope(payload_key, key_attr, key_value)
      tries ||= 5
      find_by_current_scope!(payload_key, key_attr, key_value)
    rescue Aws::S3::Errors::NoSuchKey => e
      message = "#{self}##{__method__} #{e.class} #{e.message} #{payload_key} #{key_attr} #{key_value}"

      if (tries -= 1) < 0
        logger.warn "RETRY EXHAUSTED #{message}"
        logger.info {e.backtrace.join("\n")}
        {}
      else
        logger.info "RETRY #{tries} #{message}"
        logger.info {e.backtrace.join("\n")}
        sleep 0.1 * (5 - tries)
        retry
      end
    rescue => e
      logger.warn "#{self}##{__method__} #{e.class} #{e.message} #{payload_key} #{key_attr} #{key_value}"
      logger.info {e.backtrace.join("\n")}
      {}
    end
  end
end
