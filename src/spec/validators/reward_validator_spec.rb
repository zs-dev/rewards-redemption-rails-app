require 'rails_helper'

RSpec.describe RewardValidator do
  describe '.validate' do
    shared_examples 'rejects invalid format' do |input|
      it "rejects" do
        result = RewardValidator.validate(input)
        expect(result[:valid]).to eq(false)
        expect(result[:error]).to eq('Reward id must be an integer.')
        expect(result[:status]).to eq(:unprocessable_entity)
      end
    end

    context 'with non-integer input' do
      include_examples 'rejects invalid format', 'abc'
      include_examples 'rejects invalid format', '123abc'
      include_examples 'rejects invalid format', '12.34'
      include_examples 'rejects invalid format', ''
      include_examples 'rejects invalid format', nil
      include_examples 'rejects invalid format', ' 123 '
    end

    context 'with valid format but non-existent reward' do
      before { allow(Reward).to receive(:exists?).with(-1).and_return(false) }

      it 'returns a status 404' do
        result = RewardValidator.validate(-1)
        expect(result[:valid]).to eq(false)
        expect(result[:error]).to eq('The reward does not exist.')
        expect(result[:status]).to eq(:not_found)
      end
    end

    context 'with valid format and reward exists' do
      let!(:reward1) { create(:reward, id: 123) }

      it 'passes all validation' do
        expect(RewardValidator.validate(123)).to eq({ valid: true })
      end
    end
  end
end