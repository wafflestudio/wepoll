#coding: utf-8
class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  ## Database authenticatable
  field :email,              :type => String, :null => false, :default => ""
  field :encrypted_password, :type => String, :null => false, :default => ""

  ## Recoverable
  field :reset_password_token,   :type => String
  field :reset_password_sent_at, :type => Time

  ## Rememberable
  field :remember_created_at, :type => Time

  ## Trackable
  field :sign_in_count,      :type => Integer, :default => 0
  field :current_sign_in_at, :type => Time
  field :last_sign_in_at,    :type => Time
  field :current_sign_in_ip, :type => String
  field :last_sign_in_ip,    :type => String

  ## Encryptable
  # field :password_salt, :type => String

  ## Confirmable
  # field :confirmation_token,   :type => String
  # field :confirmed_at,         :type => Time
  # field :confirmation_sent_at, :type => Time
  # field :unconfirmed_email,    :type => String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, :type => Integer, :default => 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    :type => String # Only if unlock strategy is :email or :both
  # field :locked_at,       :type => Time

  ## Token authenticatable
  # field :authentication_token, :type => String

  has_many :user_tokens

  def self.find_for_facebook_oauth(access_token, signed_in_resource=nil)
    data = access_token.extra.raw_info

    if user_token = UserToken.where(:uid => data.id, :provider => 'facebook').first
      user_token.user
    elsif signed_in_resource.nil? #만약에 현재 로그인 된 유저가 없다면 이건 새로 만드는거라고 간주한다
      user = User.create!(:email => data.email, :password => Devise.friendly_token[0,20])
      UserToken.create!(:provider => 'facebook', :uid => data.id, :user => user, :approved => true)
      user
    else #만약에 현재 로그인 된 유저가 있다면 이건 계정 통합이라 간주하고 확인 메일을 전송한다.
      token = UserToken.create!(:provider => 'facebook', :uid => data.id,
                                :user => user, :approve_key => SecureRandom.hex,
                                :approve_expire_at => 2.hour.from_now.to_i)
      AuthMailer.link_sns_verification(token)
      signed_in_resource
    end
  end

  def self.find_for_twitter_oauth(access_token, signed_in_resource=nil)
    data = access_token.extra.raw_info

    #TODO : uid 추출을 어떻게 할건가?
    if user_token = UserToken.where(:uid => 'FINDUID!!!', :provider => 'twitter').first
      user_token.user
    elsif signed_in_resource.nil? #만약에 현재 로그인 된 유저가 없다면 이건 새로 만드는거라고 간주한다
      user = User.create!(:email => data.email, :password => Devise.friendly_token[0,20])
      UserToken.create!(:provider => 'twitter', :uid => 'FINDUID!!!', :user => user, :approved => true)
      user
    else #만약에 현재 로그인 된 유저가 있다면 이건 계정 통합이라 간주하고 확인 메일을 전송한다.
      token = UserToken.create!(:provider => 'twitter', :uid => 'FINDUID!!!',
                                :user => user, :approve_key => SecureRandom.hex,
                                :approve_expire_at => 2.hour.from_now.to_i)
      AuthMailer.link_sns_verification(token)
      signed_in_resource
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"]
      end
    end
  end

  def facebook_connected?
    !facebook_token.nil?
  end

  def facebook_token
    user_tokens.where(:provider => 'facebook').first
  end

  def twitter_connected?
    !twitter_token.nil?
  end

  def twitter_token
    user_tokens.where(:provider => 'twitter').first
  end
end
