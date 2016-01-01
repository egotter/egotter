class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable

  def self.find_or_create_for_oauth_by!(auth)
    user = User.find_by(uid: auth.uid, provider: auth.provider)
    unless user
      user = User.create!(
        uid: auth.uid,
        provider: auth.provider,
        secret: auth.credentials.secret,
        token: auth.credentials.token,
        email: "#{auth.provider}-#{auth.uid}@example.com",
        password: Devise.friendly_token[4, 30])
    end
    user
  end

end
