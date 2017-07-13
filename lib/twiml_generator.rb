module TwimlGenerator
  def self.generate_gather_product(callback_url)
    response = Twilio::TwiML::VoiceResponse.new
    gather = Twilio::TwiML::Gather.new(num_digits: 1,
                                       action: callback_url,
                                       method: 'POST')
    gather.say 'Welcome to the Twilio support line!'
    gather.say 'To get specialized help with programmable voice press 1, '\
      'or press 2 for programmable SMS'

    response.append(gather)
    response.to_s
  end

  def self.generate_task_enqueue(selected_product)
    enqueue = Twilio::TwiML::Enqueue.new(nil, workflow_sid: WorkspaceInfo.instance.workflow_sid)
    enqueue.task "{\"selected_product\": \"#{selected_product}\"}"

    response = Twilio::TwiML::VoiceResponse.new
    response.append(enqueue)
    response.to_s
  end

  def self.generate_confirm_message(status)
    response = Twilio::TwiML::MessagingResponse.new
    response.message(body: "Your status has changed to #{status}")
    response.to_s
  end
end
