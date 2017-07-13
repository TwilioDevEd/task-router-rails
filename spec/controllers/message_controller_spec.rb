require 'rails_helper'

RSpec.describe MessageController, type: :controller do
  describe 'GET #incoming' do
    context 'when On is received in the message body' do
      it 'changes the worker status to Idle and sends back SMS confirmation' do
        worker_sid = 'WKXXXXXXXXXXXXXXXXX'
        idle_activity_sid = 'WAXXXXXXXXXXXXXX'
        worker_phone_number = '+1234567890'
        workspace_sid = 'WSXXXXXXXXXXXXXXX'
        WorkspaceInfo.instance.workers = {
          worker_phone_number => { sid: worker_sid, name: 'Vincent Vega' }
        }
        WorkspaceInfo.instance.idle_activity_sid = idle_activity_sid
        WorkspaceInfo.instance.workspace_sid = workspace_sid

        client_double     = double(:client)
        taskrouter_double = double(:taskrouter)
        workspace_double  = double(:workspace)
        worker_double     = double(:worker)

        allow(Twilio::REST::Client).to receive(:new).and_return(client_double)
        allow(client_double).to receive(:taskrouter)
          .and_return(taskrouter_double)
        allow(taskrouter_double).to receive(:workspaces)
          .with(workspace_sid).and_return(workspace_double)

        expect(workspace_double).to receive(:workers).with(worker_sid).and_return(worker_double)
        expect(worker_double).to receive(:update).with(activity_sid: idle_activity_sid)

        expected_response = '<Response></Response>'

        expect(TwimlGenerator).to receive(:generate_confirm_message)
          .with('Idle')
          .once
          .and_return(expected_response)

        get :incoming, Body: 'On', From: worker_phone_number

        expect(response).to be_ok
        expect(response.body).to eq(expected_response)
        expect(response.header['Content-Type']).to include('application/xml')
      end
    end
  end
end
