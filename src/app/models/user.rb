class User < ApplicationRecord
  has_many :redemptions, dependent: :destroy
  has_many :rewards, through: :redemptions
end