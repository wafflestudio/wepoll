class Pledge
  include Mongoid::Document

  field :title, type: String
  field :content, type: String
  field :like, type: Integer
  field :dislike, type: Integer

  belongs_to :politician

  has_many :messages

end