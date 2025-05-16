require 'rails_helper'

RSpec.describe RedemptionService do
  let!(:user) { create(:user, points: 1000) }
  let!(:reward) { create(:reward, points: 500) }
  let!(:too_expensive_reward) { create(:reward, points: 2000) }

  describe '.redeem_reward' do
    context 'with valid parameters' do
      it 'successfully redeems a reward' do
        initial_points = user.points
        initial_redemptions_count = Redemption.count

        RedemptionService.redeem_reward(user.id, reward.id)
        redemption = Redemption.last
        user.reload
        expect(user.points).to eq(initial_points - reward.points)
        expect(Redemption.count).to eq(initial_redemptions_count + 1)
        expect(redemption.user).to eq(user)
        expect(redemption.reward).to eq(reward)
      end
    end

    context 'with invalid user id' do
      it 'raises RecordNotFound for non-existent user' do
        expect {
          RedemptionService.redeem_reward(-1, reward.id)
        }.to raise_error(ActiveRecord::RecordNotFound, 'The user does not exist.')
      end

      it 'raises ArgumentError for non-integer user id' do
        expect {
          RedemptionService.redeem_reward('invalid', reward.id)
        }.to raise_error(ArgumentError, 'User id must be an integer.')
      end
    end

    context 'with invalid reward id' do
      it 'raises RecordNotFound for non-existent reward' do
        expect {
          RedemptionService.redeem_reward(user.id, -1)
        }.to raise_error(ActiveRecord::RecordNotFound, 'The reward does not exist.')
      end

      it 'raises ArgumentError for non-integer reward id' do
        expect {
          RedemptionService.redeem_reward(user.id, 'invalid')
        }.to raise_error(ArgumentError, 'Reward id must be an integer.')
      end
    end

    context 'with insufficient points' do
      it 'raises InsufficientPointsError' do
        expect(too_expensive_reward.points).to be > user.points
        initial_points = user.points
        initial_redemptions_count = Redemption.count

        expect {
          RedemptionService.redeem_reward(user.id, too_expensive_reward.id)
        }.to raise_error(InsufficientPointsError, 'Not enough points.')

        user.reload
        expect(user.points).to eq(initial_points)
        expect(Redemption.count).to eq(initial_redemptions_count)
      end
    end
  end

  describe '.get_redemption_history' do
    let!(:redemption1) { create(:redemption, user: user, reward: reward) }
    let!(:redemption2) { create(:redemption, user: user) }
    let!(:other_user_redemption) { create(:redemption) }

    context 'with valid user id' do
      it 'returns the user redemption history' do
        history = RedemptionService.get_redemption_history(user.id)

        history = history.as_json if history.respond_to?(:as_json)

        transformed_history = history.map do |h|
          {
            'id' => h['id'] || h[:id],
            'user_id' => h['user_id'] || h[:user_id],
            'reward' => {
              'id' => h.dig('reward', 'id') || h.dig(:reward, :id),
              'name' => h.dig('reward', 'name') || h.dig(:reward, :name),
              'points' => h.dig('reward', 'points') || h.dig(:reward, :points)
            }
          }
        end

        expected = [
          {
            'id' => redemption1.id,
            'user_id' => redemption1.user_id,
            'reward' => {
              'id' => redemption1.reward.id,
              'name' => redemption1.reward.name,
              'points' => redemption1.reward.points
            }
          },
          {
            'id' => redemption2.id,
            'user_id' => redemption2.user_id,
            'reward' => {
              'id' => redemption2.reward.id,
              'name' => redemption2.reward.name,
              'points' => redemption2.reward.points
            }
          }
        ]
        expect(transformed_history).to match_array(expected)
      end
    end

    context 'with invalid user id' do
      it 'raises RecordNotFound for non-existent user' do
        expect {
          RedemptionService.get_redemption_history(-1)
        }.to raise_error(ActiveRecord::RecordNotFound, 'The user does not exist.')
      end

      it 'raises ArgumentError for non-integer user id' do
        expect {
          RedemptionService.get_redemption_history('invalid')
        }.to raise_error(ArgumentError, 'User id must be an integer.')
      end
    end

    context 'with no redemptions' do
      let!(:new_user) { create(:user) }

      it 'returns empty relation' do
        expect(RedemptionService.get_redemption_history(new_user.id)).to be_empty
      end
    end
  end
end