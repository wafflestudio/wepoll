class UserToken
  include Mongoid::Document
  field :provider, :type => String
  field :uid, :type => String

  field :approved, :type => Boolean, :default => false
  field :approve_key, :type => String
  field :approve_expire_at, :type => Integer

  belongs_to :user
end
