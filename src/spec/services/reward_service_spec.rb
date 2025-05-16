require 'rails_helper'

RSpec.describe RewardService do
  describe '.get_reward_by_id' do
    let!(:reward1) { create(:reward, name: "Happy Meal", points: 100) }
    let!(:reward2) { create(:reward, name: "Happy Meals for Life", points: 1000) }

    context 'with valid reward id' do
      it 'returns the correct points balance' do
        expect(Reward.count).to eq(2)
        expect(RewardService.get_reward_by_id(reward1.id)).to eq(Reward.find(reward1.id))
      end
    end

    context 'handles non-integer input' do
      it 'raises ArgumentError for non-numeric data' do
        expect {
          RewardService.get_reward_by_id('fail')
        }.to raise_error(ArgumentError, 'Reward id must be an integer.')
      end
    end

    context 'with invalid reward id' do
      it 'raises ActiveRecord::RecordNotFound for non-existent reward' do
        non_existent_id = -1
        expect(Reward.where(id: non_existent_id).count).to eq(0)
        expect {
          RewardService.get_reward_by_id(non_existent_id)
        }.to raise_error(ActiveRecord::RecordNotFound, 'The reward does not exist.')
      end
    end
  end

  describe '.get_available_rewards' do
    let!(:reward1) { create(:reward, name: "Happy Meal", points: 100) }
    let!(:reward2) { create(:reward, name: "Happy Meals for Life", points: 1000) }

    it 'returns all rewards' do
      expect( RewardService.get_available_rewards).to contain_exactly(reward1, reward2)
    end
  end
end