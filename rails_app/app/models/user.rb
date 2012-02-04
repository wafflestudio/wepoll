class User
  include Mongoid::Document

  #=== Mongoid fields ===

  #=== Associtations ===
  has_many :user_tokens # user can have various ways to sign in (Facebook, Twitter etc)

  #=== Devise ===
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :trackable, :validatable, :omniauthable

  attr_accessible :email, :password, :password_confirmation

  def self.find_for_facebook_oauth(access_token, signed_in_resource=nil)
    data = access_token.extra.raw_info

    if user = User.where(:email => data.email).first
      user
    else
      User.create!(:email => data.email, :password => Devise.friendly_token[0,20])
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"]
      end
    end
  end
end
