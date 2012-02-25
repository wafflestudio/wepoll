class TweetReply
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String

  field :recommend_count, type: Integer, default: 0 # 추천
  field :opposite_count, type: Integer, default: 0  # 반대
  field :report_count, type: Integer, default: 0    # 신고

  field :vote_ips, type: Array, default: []


  belongs_to :user
  belongs_to :tweet


  def recommend(ip)
    if self.vote_ips.include? ip
      false
    else
      self.recommend_count += 1
      self.vote_ips << ip
      self.save
    end
  end

  def opposite(ip)
    if self.vote_ips.include? ip
      false
    else
      self.opposite_count += 1
      self.vote_ips << ip
      self.save
    end
  end
  def report(ip)
    if self.vote_ips.include? ip
      false
    else
      self.report_count += 1
      self.vote_ips << ip
      self.save
    end
  end

end
