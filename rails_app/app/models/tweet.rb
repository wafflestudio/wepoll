class Tweet
  include Mongoid::Document

  field :content, type: String
  field :created_at, type: DateTime

  field :recommend_count, type: Integer, default: 0       # 추천
  field :opposite_count, type: Integer, default: 0        # 반대
  field :today_recommend_count, type: Integer, default: 0 # 오늘의 추천
  field :vote_ips, type: Array, default: []


  has_many :replies
  belongs_to :politician


  def recommend
    if vote_ips.include? ip
      false
    else
      self.recommend_count += 1
      self.today_recommend_count += 1
      vote_ips << ip
    end
  end

  def opposite
    if vote_ips.include? ip
      false
    else
      self.opposite_count += 1
      vote_ips << ip
    end
  end

end
