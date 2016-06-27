class CallController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def enqueue
    digits = params[:Digits]
    selected_product = digits == '1' ? 'ProgrammableVoice' : 'ProgrammableSMS'

    twiml = TwimlGenerator.generate_task_enqueue(selected_product)

    render xml: twiml
  end

  def incoming
    twiml = TwimlGenerator.generate_gather_product(call_enqueue_path)

    render xml: twiml
  end

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

      redirect_to_voicemail(task_attributes['call_sid'])
    end

    render nothing: true
  end

  private

  def redirect_to_voicemail(call_sid)
    email         = ENV['MISSED_CALLS_EMAIL_ADDRESS']
    message       = 'Sorry, All agents are busy. Please leave a message. We\'ll call you as soon as possible'
    url_message   = { Message: message }.to_query
    redirect_url  =
      "http://twimlets.com/voicemail?Email=#{email}&#{url_message}"

    client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
    call   = client.account.calls.get(call_sid)
    call.redirect_to(redirect_url)
  end
end
