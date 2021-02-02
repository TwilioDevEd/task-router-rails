class MessageController < ApplicationController
  skip_before_action :verify_authenticity_token

  def incoming
    command     = params['Body'].downcase
    from_number = params['From']

    if command == 'off'
      status = 'Offline'
      activity_sid = WorkspaceInfo.instance.offline_activity_sid
    else
      status = 'Available'
      activity_sid = WorkspaceInfo.instance.idle_activity_sid
    end

    worker_sid = WorkspaceInfo.instance.workers[from_number][:sid]
    client
      .workspaces(WorkspaceInfo.instance.workspace_sid)
      .workers(worker_sid)
      .fetch
      .update(activity_sid: activity_sid)

    render xml: TwimlGenerator.generate_confirm_message(status)
  end

  private

  def client
    client_instance = Twilio::REST::Client.new(
      ENV['TWILIO_ACCOUNT_SID'],
      ENV['TWILIO_AUTH_TOKEN']
    )

    client_instance.taskrouter.v1
  end
end
