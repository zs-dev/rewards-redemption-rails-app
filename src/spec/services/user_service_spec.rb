require 'rails_helper'

RSpec.describe UserService do
  describe '.get_balance' do
    let!(:user1) { create(:user, points: 500) }
    let!(:user2) { create(:user, points: 0) }

    context 'with valid user id' do
      it 'returns the correct points balance' do
        expect(User.count).to eq(2)
        expect(User.find(user1.id).points).to eq(500)
        expect(UserService.get_balance(user1.id)).to eq(500)
        expect(User.find(user2.id).points).to eq(0)
      end
    end

    context 'handles non-integer input' do
      it 'raises ArgumentError for non-numeric string' do
        expect {
          UserService.get_balance('fail')
        }.to raise_error(ArgumentError, 'User id must be an integer.')
      end
    end

    context 'with invalid user id' do
      it 'raises ActiveRecord::RecordNotFound for non-existent user' do
        non_existent_id = -1
        expect(User.where(id: non_existent_id).count).to eq(0)
        expect {
          UserService.get_balance(non_existent_id)
        }.to raise_error(ActiveRecord::RecordNotFound, 'The user does not exist.')
      end
    end
  end
end