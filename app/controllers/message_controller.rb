class MessageController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def incoming
    command     = params['Body'].downcase
    from_number = params['From']

    if command == 'off'
      status = 'Offline'
      activity_sid = WorkspaceInfo.instance.offline_activity_sid
    else
      status = 'Idle'
      activity_sid = WorkspaceInfo.instance.idle_activity_sid
    end

    worker_sid = WorkspaceInfo.instance.workers[from_number][:sid]
    client
      .workspace
      .workers
      .get(worker_sid)
      .update(activity_sid: activity_sid)

    render xml: TwimlGenerator.generate_confirm_message(status)
  end

  private

  def client
    Twilio::REST::Client.new(
      ENV['TWILIO_ACCOUNT_SID'],
      ENV['TWILIO_AUTH_TOKEN']
    )
  end
end
