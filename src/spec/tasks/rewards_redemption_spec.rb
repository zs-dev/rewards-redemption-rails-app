require 'rails_helper'
require 'rake'
require 'webmock/rspec'

RSpec.describe 'utils:rewards_redemption' do
  let(:task_name) { 'utils:rewards_redemption' }
  let!(:user) { create(:user, name: 'Test User', email: 'test@example.com') }
  let(:api_base_url) { 'http://test.com' }

  before(:all) do
    Rails.application.load_tasks
  end
  #mock the config
  before do
    allow(Rails.application).to receive(:config_for).with(:rewards).and_return(
      {
        'default_user' => user.email,
        'api_base_url' => api_base_url
      }
    )
  end
  context 'when checking balance (option 1)' do
    it 'displays balance and returns to menu' do
      stub_request(:get, "#{api_base_url}/users/#{user.id}/balance")
        .with(headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: { balance: 1000 }.to_json, headers: { 'Content-Type' => 'application/json' })

      prompt = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      allow(prompt).to receive(:ask).and_return('1', '5')
      allow(prompt).to receive(:keypress)

      output = StringIO.new
      original_stdout = $stdout
      $stdout = output

      begin
        Rake::Task[task_name].reenable
        Rake::Task[task_name].invoke
      ensure
        $stdout = original_stdout
      end

      expect(output.string).to include("Logged in as: #{user.name} (#{user.email})")
      expect(output.string).to include("Current balance: 1000 points")
      expect(output.string).to include("Goodbye!")
    end
  end

  context 'when selecting exit option (option 5)' do
    it 'displays goodbye message and exits' do
      prompt = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      allow(prompt).to receive(:ask).and_return('5')
      allow(prompt).to receive(:keypress)

      output = StringIO.new
      original_stdout = $stdout
      $stdout = output

      begin
        Rake::Task[task_name].reenable
        Rake::Task[task_name].invoke
      ensure
        $stdout = original_stdout
      end

      expect(output.string).to include("Logged in as: #{user.name} (#{user.email})")
      expect(output.string).to include("Goodbye!")
    end
  end
  context 'when listing rewards (option 2)' do
    it 'displays available rewards in table format' do
      rewards_data = [
        { "id" => 1, "name" => "Free Coffee", "points" => 100 },
        { "id" => 2, "name" => "Movie Ticket", "points" => 500 }
      ].to_json

      stub_request(:get, "#{api_base_url}/rewards")
        .to_return(status: 200, body: rewards_data, headers: { 'Content-Type' => 'application/json' })

      prompt = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      allow(prompt).to receive(:ask).and_return('2', '5')
      allow(prompt).to receive(:keypress)

      output = Tempfile.new('output')
      begin
        $stdout = output
        Rake::Task[task_name].reenable
        Rake::Task[task_name].invoke
        output.rewind
        captured_output = output.read

        aggregate_failures do
          expect(captured_output).to include("Free Coffee")
          expect(captured_output).to include("Movie Ticket")
          expect(captured_output).to include("100")
          expect(captured_output).to include("500")
          expect(captured_output).to match(/ID.*Name.*Points/i)
        end
      ensure
        $stdout = STDOUT
        output.close
        output.unlink
      end
    end
  end
  context 'when viewing redemption history (option 4)' do
    it 'displays the redemption history in table format' do
      redemptions_data = [
        { "id" => 1, "reward" => { "id" => 1, "name" => "Free Coffee", "points" => 100 }, "user_id" => user.id, "created_at" => "2025-05-15T23:58:05.406872Z", "updated_at" => "2025-05-15T23:58:05.409978Z" },
        { "id" => 2, "reward" => { "id" => 2, "name" => "Movie Ticket", "points" => 500 }, "user_id" => user.id, "created_at" => "2025-05-14T23:58:05.406872Z", "updated_at" => "2025-05-14T23:58:05.409978Z" }
      ].to_json

      stub_request(:get, "#{api_base_url}/users/#{user.id}/redemptions/history")
        .to_return(status: 200, body: redemptions_data, headers: { 'Content-Type' => 'application/json' })

      prompt = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      allow(prompt).to receive(:ask).and_return('4', '5')
      allow(prompt).to receive(:keypress)

      output = Tempfile.new('output')
      begin
        $stdout = output
        Rake::Task[task_name].reenable
        Rake::Task[task_name].invoke
        output.rewind
        captured_output = output.read

        aggregate_failures do
          expect(captured_output).to match(/Date.*Reward.*Points/i)
          expect(captured_output).to include("2025-05-15T23:58:05.406872Z")
          expect(captured_output).to include("Free Coffee")
          expect(captured_output).to include("100")
          expect(captured_output).to include("2025-05-15T23:58:05.406872Z")
          expect(captured_output).to include("Movie Ticket")
          expect(captured_output).to include("500")
        end
      ensure
        $stdout = STDOUT
        output.close
        output.unlink
      end
    end
  end
  context 'when user does not exist' do
    it 'shows error and exits' do
      allow(Rails.application).to receive(:config_for).with(:rewards).and_return(
        { 'default_user' => 'nonexistent@example.com' }
      )

      prompt = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      allow(prompt).to receive(:ask).and_return('5')
      allow(prompt).to receive(:keypress)

      output = StringIO.new
      original_stdout = $stdout
      $stdout = output

      begin
        Rake::Task[task_name].reenable
        Rake::Task[task_name].invoke
      ensure
        $stdout = original_stdout
      end

      aggregate_failures do
        expect(output.string).to include("User not found: nonexistent@example.com")
        expect(output.string).to include("Goodbye!")
      end
    end
  end
  describe 'redeem_reward' do
    context 'successful redemption' do
      let(:reward) { { 'id' => 1, 'name' => 'Free Coffee', 'points' => 200 } }

      it 'redeems reward successfully' do
        stub_request(:get, "#{api_base_url}/rewards/#{reward['id']}")
          .to_return(status: 200, body: reward.to_json)

        stub_request(:post, "#{api_base_url}/redeem")
          .with(body: { user_id: user.id, reward_id: 1 }.to_json)
          .to_return(status: 201, body: {}.to_json)

        stub_request(:get, "#{api_base_url}/users/#{user.id}/balance")
          .with(headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: { balance: 800 }.to_json, headers: { 'Content-Type' => 'application/json' })

        prompt = instance_double(TTY::Prompt)
        allow(TTY::Prompt).to receive(:new).and_return(prompt)
        allow(prompt).to receive(:ask).and_return('3', '1', 'y', '5')
        allow(prompt).to receive(:yes?).and_return(true)

        output = StringIO.new
        original_stdout = $stdout
        $stdout = output

        begin
          Rake::Task[task_name].reenable
          Rake::Task[task_name].invoke
        ensure
          $stdout = original_stdout
        end
        aggregate_failures do
          expect(output.string).to include("Reward redeemed successfully!")
          expect(output.string).to include("Remaining balance: 800")
          expect(output.string).to include("Goodbye!")
        end
      end
    end
  end
  context 'insufficient points' do
    let(:reward) { { 'id' => 1, 'name' => 'Free Coffee', 'points' => 200 } }

    it 'fails to redeem reward when user does not have enough points' do
      stub_request(:get, "#{api_base_url}/rewards/#{reward['id']}")
        .to_return(status: 200, body: reward.to_json)
      stub_request(:post, "#{api_base_url}/redeem")
        .with(
          body: { user_id: user.id, reward_id: 1 }.to_json
        )
        .to_return(
          status: 422,
          body: { "error" => "Not enough points." }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      prompt = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      allow(prompt).to receive(:ask).and_return('3', '1', 'y', '5')
      allow(prompt).to receive(:yes?).and_return(true)

      output = StringIO.new
      original_stdout = $stdout
      $stdout = output

      begin
        Rake::Task[task_name].reenable
        Rake::Task[task_name].invoke
      ensure
        $stdout = original_stdout
      end
      aggregate_failures do
        expect(output.string).to include("Redemption failed: Not enough points.")
        expect(output.string).to include("Goodbye!")
      end
    end
  end
  context 'invalid reward id' do
    it 'shows error when reward ID does not exist' do
      stub_request(:get, "#{api_base_url}/rewards/-1")
        .to_return(
          status: 404,
          body: { error: 'The reward does not exist.' }.to_json,
          )
      prompt = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      allow(prompt).to receive(:ask).and_return('3', '-1', '5')
      allow(prompt).to receive(:keypress)

      output = StringIO.new
      original_stdout = $stdout
      $stdout = output

      begin
        Rake::Task[task_name].reenable
        Rake::Task[task_name].invoke
      ensure
        $stdout = original_stdout
      end

      aggregate_failures do
        expect(output.string).to include("No reward found with ID: -1. Select option 2 to see reward IDs.")
        expect(output.string).to include("Goodbye!")
      end
    end
  end
end