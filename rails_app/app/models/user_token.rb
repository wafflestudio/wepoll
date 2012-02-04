class UserToken
  include Mongoid::Document
  belongs_to :user
end
