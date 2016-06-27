require 'rails_helper'

RSpec.describe CallController, type: :controller do
  describe 'GET #incoming' do
    it 'responds with welcome and Gather TwiML' do
      expected_response = '<Response></Response>'

      expect(TwimlGenerator).to receive(:generate_gather_product)
        .with(call_enqueue_path)
        .once
        .and_return(expected_response)

      get :incoming

      expect(response).to be_ok
      expect(response.body).to eq(expected_response)
      expect(response.header['Content-Type']).to include('application/xml')
    end
  end

  describe 'POST #enqueue' do
    it 'responds with enqueue and task TwiML' do
      expected_response = '<Response></Response>'

      expect(TwimlGenerator).to receive(:generate_task_enqueue)
        .with('ProgrammableVoice')
        .once
        .and_return(expected_response)

      post :enqueue, Digits: 1

      expect(response).to be_ok
      expect(response.body).to eq(expected_response)
      expect(response.header['Content-Type']).to include('application/xml')
    end
  end

  describe 'POST #assign' do
    default_activity_sid = 'WAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

    before do
      expect(WorkspaceInfo).to receive_message_chain(:instance, :post_work_activity_sid)
        .and_return(default_activity_sid)
    end
    it 'responds with json instruction to dequeue' do
      expected_response = {
        instruction: 'dequeue',
        post_work_activity_sid: default_activity_sid
      }.to_json

      post :assignment

      expect(response).to be_ok
      expect(response.header['Content-Type']).to include('application/json')
      expect(response.body).to eq(expected_response)
    end
  end

  describe 'POST #events' do
    context 'received event is workflow.timeout or task.canceled' do
      from_number      = '+15551234567'
      selected_product = 'SMS'
      call_sid = 'CAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
      task_attributes  =
        "{\"from\": \"#{from_number}\", \"selected_product\": \"#{selected_product}\", \"call_sid\": \"#{call_sid}\"}"

      before do
        email         = ENV['MISSED_CALLS_EMAIL_ADDRESS']
        message       = 'Sorry, All agents are busy. Please leave a message. We\'ll call you as soon as possible'
        url_message   = { Message: message }.to_query
        redirect_url  =
          "http://twimlets.com/voicemail?Email=#{email}&#{url_message}"
        client_double = double(:client)
        calls_double  = double(:calls)
        call_double   = double(:call)

        allow(Twilio::REST::Client).to receive(:new).and_return(client_double)
        allow(client_double).to receive_message_chain(:account, :calls).and_return(calls_double)
        expect(calls_double).to receive(:get).with(call_sid).and_return(call_double)
        expect(call_double).to receive(:redirect_to)
          .with(redirect_url)
      end

      it 'saves missed calls in the database' do
        expect(MissedCall.count).to eq(0)

        post :events,
             EventType: 'task.canceled',
             TaskAttributes: task_attributes

        expect(MissedCall.count).to eq(1)
        expect(MissedCall.first.phone_number).to eq(from_number)
        expect(MissedCall.first.selected_product).to eq(selected_product)
      end

      it 'routes call to voice mail' do
        post :events,
             EventType: 'workflow.timeout',
             TaskAttributes: task_attributes
      end
    end

    context 'received event is not workflow.timeout or task.canceled' do
      it 'saves nothing in the database' do
        expect { post :events, EventType: 'any.event' }
          .to_not change { MissedCall.count }.from(0)
      end
    end
  end
end
