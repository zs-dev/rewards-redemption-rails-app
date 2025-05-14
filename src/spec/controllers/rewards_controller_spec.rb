require 'rails_helper'

RSpec.describe RewardsController, type: :controller do
  let!(:reward1) { create(:reward, name: "Happy Meal", points: 100) }
  let!(:reward2) { create(:reward, name: "Free Coffee", points: 50) }

  describe '#index' do
    it 'returns all rewards' do
      get :index

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response.size).to eq(2)
      expect(json_response[0]).to eq(JSON.parse(reward1.to_json))
      expect(json_response[1]).to eq(JSON.parse(reward2.to_json))
    end

    context 'when no rewards available' do
      before { Reward.destroy_all }

      it 'returns empty array' do
        get :index

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  describe '#show' do
    context 'with valid reward id' do
      it 'returns the reward details' do
        get :show, params: { id: reward1.id }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(5)
        expect(json_response).to eq(JSON.parse(reward1.to_json))
      end
    end

    context 'with invalid reward id' do
      it 'returns 404 for non-existent reward' do
        get :show, params: { id: -1 }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error')
      end

      it 'returns 422 for non-integer id' do
        get :show, params: { id: 'invalid' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('error')
      end
    end
  end
end