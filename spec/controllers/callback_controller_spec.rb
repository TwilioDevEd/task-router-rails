require 'rails_helper'

RSpec.describe CallbackController, type: :controller do
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
    let(:client_double) { double(:client) }

    before do
      allow(Twilio::REST::Client).to receive(:new).and_return(client_double)
    end

    context 'received event is worker.activity.update' do
      it 'notifies the worker that he/she has gone offline' do
        messages_double   = double(:messages)
        worker_number     = '+1234567890'
        worker_attributes = "{\"contact_uri\":\"#{worker_number}\"}"
        message_body      = 'Your status has changed to Offline. Reply with '\
                            '"On" to get back Online'

        expect(client_double).to receive_message_chain(:account, :messages).and_return(messages_double)
        expect(messages_double)
          .to receive(:create)
          .with(from: ENV['TWILIO_NUMBER'], to: worker_number, body: message_body)

        post :events,
             EventType: 'worker.activity.update',
             WorkerAttributes: worker_attributes,
             WorkerActivityName: 'Offline'
      end
    end

    context 'received event is workflow.timeout or task.canceled' do
      from_number      = '+15551234567'
      selected_product = 'SMS'
      call_sid = 'CAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
      task_attributes  =
        "{\"from\": \"#{from_number}\", \"selected_product\": \"#{selected_product}\", \"call_sid\": \"#{call_sid}\"}"

      it 'saves missed calls in the database' do
        expect(MissedCall.count).to eq(0)

        post :events,
             EventType: 'task.canceled',
             TaskAttributes: task_attributes

        expect(MissedCall.count).to eq(1)
        expect(MissedCall.first.phone_number).to eq(from_number)
        expect(MissedCall.first.selected_product).to eq(selected_product)
      end

      it 'routes call to voice mail when event is workflow.timeout' do
        email         = ENV['MISSED_CALLS_EMAIL_ADDRESS']
        message       = 'Sorry, All agents are busy. Please leave a message. We\'ll call you as soon as possible'
        url_message   = { Message: message }.to_query
        redirect_url  =
          "http://twimlets.com/voicemail?Email=#{email}&#{url_message}"
        calls_double  = double(:calls)
        call_double   = double(:call)

        allow(client_double).to receive_message_chain(:account, :calls).and_return(calls_double)
        expect(calls_double).to receive(:get).with(call_sid).and_return(call_double)
        expect(call_double).to receive(:redirect_to)
          .with(redirect_url)

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

      it 'doesn\'t redirect the call' do
        expect(client_double).to_not receive(:account)

        post :events, EventType: 'any.event'
      end
    end
  end
end
