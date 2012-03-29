class Pledge
  include Mongoid::Document

  field :title, type: String
  field :content, type: String
  field :like, type: Integer, default:0
  field :dislike, type: Integer, default:0

  belongs_to :politician
  has_and_belongs_to_many :user, inverse_of: nil

  has_many :messages

  def liked_by(user)
    unless user_ids.include? user.id
      user_ids << user.id
      user.like_pledges << self
      user.save!
      save!
      inc :like, 1
    else
      -1
    end
  end

  def disliked_by(user)
    unless user_ids.include? user.id
      user_ids << user.id
      user.dislike_pledges << self
      user.save!
      save!
      inc :dislike, 1
    else
      -1
    end
  end
end
