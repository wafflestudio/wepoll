class UserToken
  include Mongoid::Document
  field :provider, :type => String
  field :uid, :type => String

  field :approved, :type => Boolean, :default => false
  field :approve_key, :type => String
  field :approve_expire_at, :type => Integer

  field :access_token_secret, type: String
  field :access_token, type: String

  belongs_to :user
end
