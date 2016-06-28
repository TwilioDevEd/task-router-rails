module TwimlGenerator
  def self.generate_gather_product(callback_url)
    Twilio::TwiML::Response.new do |r|
      r.Gather numDigits: 1, action: callback_url, method: 'POST' do |g|
        g.Say 'Welcome to the Twilio support line!'
        g.Say 'To get specialized help with programmable voice press 1, '\
              'or press 2 for programmable SMS'
      end
    end.to_xml
  end

  def self.generate_task_enqueue(selected_product)
    Twilio::TwiML::Response.new do |r|
      r.Enqueue workflowSid: WorkspaceInfo.instance.workflow_sid do |e|
        e.Task "{\"selected_product\": \"#{selected_product}\"}"
      end
    end.to_xml
  end

  def self.generate_confirm_message(status)
    Twilio::TwiML::Response.new do |r|
      r.Message "Your status has changed to #{status}"
    end.to_xml
  end
end
