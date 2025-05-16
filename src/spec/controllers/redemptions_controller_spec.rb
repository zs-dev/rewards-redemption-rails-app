require 'rails_helper'

RSpec.describe RedemptionsController, type: :controller do
  let!(:user) { create(:user, points: 1000) }
  let!(:reward) { create(:reward, points: 500) }
  let!(:redemption) { create(:redemption, user: user, reward: reward) }

  describe '#history' do
    context 'with valid user_id' do
      it 'returns redemption history' do
        get :history, params: { user_id: user.id }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(1)
        expect(json_response[0]['id']).to eq(1)
        expect(json_response[0]['user_id']).to eq(1)

        expect(json_response[0]['reward']['id']).to eq(1)
        expect(json_response[0]['reward']['name']).to eq('Happy meal')
        expect(json_response[0]['reward']['points']).to eq(500)

      end
    end

    context 'with invalid user_id' do
      it 'returns 404 for non-existent user' do
        get :history, params: { user_id: -1 }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('The user does not exist.')
      end

      it 'returns 422 for non-integer user_id' do
        get :history, params: { user_id: 'invalid' }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('User id must be an integer.')
      end
    end
  end

  describe '#redeem' do
    context 'with valid parameters' do
      it 'creates a redemption' do
        initial_redemptions = Redemption.count
        initial_user_redemptions = user.redemptions.count
        post :redeem, params: { user_id: user.id, reward_id: reward.id }

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['user_id']).to eq(user.id)
        expect(json_response['reward_id']).to eq(reward.id)

        expect(Redemption.count).to eq(initial_redemptions + 1)
        expect(user.redemptions.count).to eq(initial_user_redemptions + 1)

        new_redemption = Redemption.last
        expect(new_redemption.user).to eq(user)
        expect(new_redemption.reward).to eq(reward)
      end
    end

    context 'with invalid parameters' do
      it 'returns 404 for non-existent user' do
        post :redeem, params: { user_id: -1, reward_id: reward.id }
        expect(response).to have_http_status(:not_found)
        response_body = JSON.parse(response.body)
        expect(response_body['error']).to eq('The user does not exist.')
      end

      it 'returns 404 for non-existent reward' do
        post :redeem, params: { user_id: user.id, reward_id: -1 }
        expect(response).to have_http_status(:not_found)
        response_body = JSON.parse(response.body)
        expect(response_body['error']).to eq('The reward does not exist.')
      end

      it 'returns 422 for insufficient points' do
        expensive_reward = create(:reward, points: 2000)
        expect(expensive_reward.points).to be > user.points
        post :redeem, params: { user_id: user.id, reward_id: expensive_reward.id }
        expect(response).to have_http_status(:unprocessable_entity)
        response_body = JSON.parse(response.body)
        expect(response_body['error']).to eq('Not enough points.')
      end

      it 'returns 422 for non-integer parameter for user' do
        post :redeem, params: { user_id: 'invalid', reward_id: reward.id }
        expect(response).to have_http_status(:unprocessable_entity)
        response_body = JSON.parse(response.body)
        expect(response_body['error']).to eq('User id must be an integer.')
      end

      it 'returns 422 for non-integer parameter for reward' do
        post :redeem, params: { user_id: user.id, reward_id: 'invalid' }
        expect(response).to have_http_status(:unprocessable_entity)
        response_body = JSON.parse(response.body)
        expect(response_body['error']).to eq('Reward id must be an integer.')
      end
    end
  end
end