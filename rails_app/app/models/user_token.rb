class UserToken #this model holds uid and provider
  include Mongoid::Document
  belongs_to :user

  #=== Mongoid fields ===
  field :provider, type: String
  field :uid, type: String
end
