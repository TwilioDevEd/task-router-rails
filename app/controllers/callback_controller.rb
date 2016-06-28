class CallbackController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def assignment
    instruction = {
      instruction: 'dequeue',
      post_work_activity_sid: WorkspaceInfo.instance.post_work_activity_sid
    }

    render json: instruction
  end

  def events
    event_type = params[:EventType]

    if ['workflow.timeout', 'task.canceled'].include?(event_type)
      task_attributes = JSON.parse(params[:TaskAttributes])

      MissedCall.create(
        selected_product: task_attributes['selected_product'],
        phone_number: task_attributes['from']
      )

      redirect_to_voicemail(task_attributes['call_sid']) if event_type == 'workflow.timeout'
    elsif event_type == 'worker.activity.update' &&
          params[:WorkerActivityName] == 'Offline'

      worker_attributes = JSON.parse(params[:WorkerAttributes])
      notify_offline_status(worker_attributes['contact_uri'])
    end

    render nothing: true
  end

  private

  def notify_offline_status(phone_number)
    message = 'Your status has changed to Offline. Reply with '\
              '"On" to get back Online'
    client.account.messages.create(
      to: phone_number,
      from: ENV['TWILIO_NUMBER'],
      body: message
    )
  end

  def redirect_to_voicemail(call_sid)
    email         = ENV['MISSED_CALLS_EMAIL_ADDRESS']
    message       = 'Sorry, All agents are busy. Please leave a message. We\'ll call you as soon as possible'
    url_message   = { Message: message }.to_query
    redirect_url  =
      "http://twimlets.com/voicemail?Email=#{email}&#{url_message}"

    call = client.account.calls.get(call_sid)
    call.redirect_to(redirect_url)
  end

  def client
    Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
  end
end
