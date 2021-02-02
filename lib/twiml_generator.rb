module TwimlGenerator
  def self.generate_gather_product(callback_url)
    Twilio::TwiML::VoiceResponse.new do |response|
      response.gather(numDigits: 1, action: callback_url, method: 'POST') do |gather|
        gather.say message: 'Welcome to the Twilio support line!'
        gather.say message: 'To get specialized help with programmable voice press 1, '\
          'or press 2 for programmable SMS'
      end
    end.to_s
  end

  def self.generate_task_enqueue(selected_product)
    Twilio::TwiML::VoiceResponse.new do |response|
      response.enqueue(workflow_sid: WorkspaceInfo.instance.workflow_sid) do |e|
        e.task "{\"selected_product\": \"#{selected_product}\"}"
      end
    end.to_s
  end

  def self.generate_confirm_message(status)
    response = Twilio::TwiML::MessagingResponse.new
    response.message(body: "Your status has changed to #{status}")
    response.to_s
  end
end
