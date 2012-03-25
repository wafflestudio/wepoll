#coding: utf-8
class User
  include Mongoid::Document
  include Mongoid::Paperclip
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  STATUS_OK = "ok"
  STATUS_SUSPEND = "suspended"

  SUSPEND_REASONS = ["욕설", "비방", "인신공격", "허위사실"]

  ## Database authenticatable

  field :email,              :type => String, :default => ""
  #  이메일이 아닌 userid가 identifier이다.
  field :userid,              :type => String, :null => false, :default => ""
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

  field :agree_provision, :type => Boolean, :default => false
  field :agree_privacy, :type => Boolean, :default => false

  field :nickname, :type => String

  ## Facebook 친구에게 앱 리퀘스트 보내는 리스트
  field :fb_req_friend_ids, type: Array, default: []

  validates :agree_provision,:inclusion => {:in => [true]}
  validates :agree_privacy,:inclusion => {:in => [true]}

  ## 계정정지
  field :status, type: Hash, default: {"status" => STATUS_OK}
  field :total_suspends, type: Array, default: []

  def email_required?
    false
  end

  has_mongoid_attached_file :profile_picture,
    :styles => {:square50 => "50x50#"},
    :default_url => "/system/user_profile_photos/anonymous_:style.gif",
    :url => "/system/user_profile_pictures/:id/:style",
    :path => Rails.root.to_s + "/public/system/user_profile_pictures/:id/:style"

  has_many :messages

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

  ## User settings
  field :auto_post_facebook, :type => Boolean, :default => true
  field :auto_post_twitter, :type => Boolean, :default => true

  has_many :user_tokens, :dependent => :destroy

  # tweet forum association

  has_many :tweet_replies
  has_and_belongs_to_many :like_tweet_replies, :class_name => "TweetReply", :inverse_of => :like_users
  has_and_belongs_to_many :blame_tweet_replies, :class_name => "TweetReply", :inverse_of => :blame_users
  has_and_belongs_to_many :like_link_replies, :class_name => "LinkReply", :inverse_of => :like_users
  has_and_belongs_to_many :blame_link_replies, :class_name => "LinkReply", :inverse_of => :blame_users
  has_and_belongs_to_many :like_tweets, :class_name => "Tweet", :inverse_of => :like_users
  has_and_belongs_to_many :like_timeline_entries, :class_name => "TimelineEntry", :inverse_of => :like_users
  has_and_belongs_to_many :blame_timeline_entries, :class_name => "TimelineEntry", :inverse_of => :blame_users

  #timeline entry
  has_many :timeline_entries, :inverse_of => :user

  has_many :link_replies, :inverse_of => :user

  #pledges
  has_and_belongs_to_many :like_pledges, :class_name => "Pledge", inverse_of: nil
  has_and_belongs_to_many :dislike_pledges, :class_name => "Pledge", inverse_of: nil

  def self.find_for_facebook_oauth(access_token, signed_in_resource=nil)

    uid = access_token.uid
    Rails.logger.info "find_for_facebook_oauth, uid = " + uid
    if user_token = UserToken.where(:provider => 'facebook', :uid => uid).first
      user_token.user
#    elsif signed_in_resource.nil?
#      user = User.create!(:userid => "fb_#{data["id"]}", :email => data.email, :password => Devise.friendly_token[0,20])
#      UserToken.create!(:provider => 'facebook', :uid => data.id, :user => user, :approved => true)
#      user
    end
  end

  def self.find_for_twitter_oauth(access_token, signed_in_resource=nil)
    uid = access_token.uid

    if user_token = UserToken.where(:provider => 'twitter', :uid => uid).first
      user_token.user
#    elsif signed_in_resource.nil? #만약에 현재 로그인 된 유저가 없다면 이건 새로 만드는거라고 간주한다
#      user = User.create!(:userid => "tw_#{uid}", :password => Devise.friendly_token[0,20])
#      UserToken.create!(:provider => 'twitter', :uid => uid, :user => user, :approved => true,
#                        :access_token_secret => secret,
#                        :access_token => token)
#      user
    end
  end

  # def self.find_for_facebook_oauth(access_token, signed_in_resource=nil)
  #   data = access_token.extra.raw_info

  #   if user_token = UserToken.where(:uid => data.id, :provider => 'facebook', :approved => true).first
  #     user_token.user
  #   elsif signed_in_resource.nil? #만약에 현재 로그인 된 유저가 없다면 이건 새로 만드는거라고 간주한다
  #     user = User.create!(:email => data.email, :password => devise.friendly_token[0,20])
  #     UserToken.create!(:provider => 'facebook', :uid => data.id, :user => user, :approved => true)
  #     user
  #   else #만약에 현재 로그인 된 유저가 있다면 이건 계정 통합이라 간주하고 확인 메일을 전송한다.
  #     token = UserToken.create!(:provider => 'facebook', :uid => data.id,
  #                               :user => user, :approve_key => SecureRandom.hex,
  #                               :approve_expire_at => 2.hour.from_now.to_i)
  #     AuthMailer.link_sns_verification(token)
  #     signed_in_resource
  #   end
  # end

  # def self.find_for_twitter_oauth(access_token, signed_in_resource=nil)
  #   data = access_token.extra.raw_info
  #   uid = access_token.uid
  #   secret = access_token.credentials.secret
  #   token = access_token.credentials.token

  #   if user_token = UserToken.where(:uid => uid, :provider => 'twitter', :approved => true).first
  #     user_token.update_attributes(:access_token_secret => secret,
  #                                  :access_token => token)
  #     user_token.user
  #   elsif signed_in_resource.nil? #만약에 현재 로그인 된 유저가 없다면 이건 새로 만드는거라고 간주한다
  #     user = User.create!(:email => data.email, :password => Devise.friendly_token[0,20])
  #     UserToken.create!(:provider => 'twitter', :uid => uid, :user => user, :approved => true,
  #                       :access_token_secret => secret,
  #                       :access_token => token)
  #     user
  #   else #만약에 현재 로그인 된 유저가 있다면 이건 계정 통합이라 간주하고 확인 메일을 전송한다.
  #     #TODO : 2시간 이후에 확인되지 않은 user_token을 실제로 지우는 로직이 필요하다
  #     user_token = UserToken.create!(:provider => 'twitter', :uid => uid,
  #                                    :user => user, :approve_key => SecureRandom.hex,
  #                                    :approve_expire_at => 2.hour.from_now.to_i,
  #                                    :access_token => token, :access_token_secret => secret)

  #     AuthMailer.link_sns_verification(user_token)
  #     signed_in_resource
  #   end
  # end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"]
      end
    end
  end

  def facebook_connected?
    fb_token = facebook_token
    !fb_token.nil? && fb_token.approved
  end

  def facebook_token
    user_tokens.where(:provider => 'facebook').first
  end

  def twitter_connected?
    tw_token = twitter_token
    !tw_token.nil? && tw_token.approved
  end

  def twitter_token
    user_tokens.where(:provider => 'twitter').first
  end

  def send_tweet(options={})
  end

  def send_facebook(options={}) #facebook access token is very short-term, so options[:access_token] should be provided
    raise "No access_token given" unless options[:access_token]
    raise "No message given" unless options[:message]

    client = OAuth2::Client.new(FACEBOOK_CLIENT[:key],
                                FACEBOOK_CLIENT[:secret],
                                :site => "https://graph.facebook.com")
    token = OAuth2::AccessToken.new(client, options[:access_token])
    begin
    token.post("/#{facebook_token.uid}/feed?access_token=#{options[:access_token]}&message=#{options[:message]}")
    rescue OAuth2::Error => e
      Rails.logger.info e.response.body
      raise e
    end
  end
end
