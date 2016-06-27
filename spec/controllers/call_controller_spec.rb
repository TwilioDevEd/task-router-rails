require 'rails_helper'

RSpec.describe CallController, type: :controller do
  describe 'GET #incoming' do
    it 'responds with welcome and Gather TwiML' do
      expected_response = '<Response></Response>'

      expect(TwimlGenerator).to receive(:generate_gather_product)
        .with(call_incoming_path)
        .once
        .and_return(expected_response)

      get :incoming

      expect(response).to be_ok
      expect(response.body).to eq(expected_response)
      expect(response.header['Content-Type']).to include('application/xml')
    end
  end

  describe 'GET #enqueue' do
    it 'responds with enqueue and task TwiML' do
      expected_response = '<Response></Response>'

      expect(TwimlGenerator).to receive(:generate_task_enqueue)
        .with('ProgrammableVoice')
        .once
        .and_return(expected_response)

      get :enqueue, Digits: 1

      expect(response).to be_ok
      expect(response.body).to eq(expected_response)
      expect(response.header['Content-Type']).to include('application/xml')
    end
  end
end
