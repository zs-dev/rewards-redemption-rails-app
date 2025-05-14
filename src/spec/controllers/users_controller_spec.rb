require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe '#balance' do
    let!(:user) { create(:user, points: 1000) }

    context 'with valid user id' do
      it 'returns the user balance' do
        get :balance, params: { id: user.id }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'balance' => 1000 })
      end
    end

    context 'with invalid user id' do
      it 'returns 404 for non-existent user' do
        get :balance, params: { id: -1 }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error')
      end

      it 'returns 422 for non-integer id' do
        get :balance, params: { id: 'invalid' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('error')
      end
    end
  end
end