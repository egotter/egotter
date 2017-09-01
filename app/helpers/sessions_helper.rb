module SessionsHelper
  def fingerprint
    if from_crawler?
      return -1
    end

    if session[:fingerprint].nil? || session[:fingerprint].to_s == '-1'
      session[:fingerprint] = session.id.nil? ? '-1' : session.id
    end

    if session[:fingerprint] == '-1'
      digest = Digest::MD5.hexdigest("#{Time.zone.now.to_i + rand(1000)}")
      session[:fingerprint] = "digest-#{digest}"
    end

    session[:fingerprint]
  end
end
