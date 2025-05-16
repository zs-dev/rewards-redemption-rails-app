class Reward < ApplicationRecord
  has_many :redemptions, dependent: :destroy
  has_many :users, through: :redemptions
end