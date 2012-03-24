class Vote
  include Mongoid::Document
  
  has_one :bill
  
  field :supported_per_parties, type: Hash 
  field :dissented_per_parties, type: Hash
  field :attended_per_parties, type: Hash
  field :absented_per_parties, type: Hash
  
end
