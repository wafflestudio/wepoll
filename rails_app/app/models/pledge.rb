class Pledge
  include Mongoid::Document

  field :title, type: String
  field :content, type: String
  field :like, type: Integer, default:0
  field :dislike, type: Integer, default:0

  belongs_to :politician

  has_many :messages

end
