class Pledge
  include Mongoid::Document

  field :title, type: String
  field :content, type: String
  field :election_count, type: Integer

  belongs_to :politician
  
  has_many :messages

end
