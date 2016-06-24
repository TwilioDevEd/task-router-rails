module TwimlGenerator
  def self.generate_gather_product(callback_url)
    Twilio::TwiML::Response.new do |r|
      r.Gather numDigits: 1, action: callback_url, method: 'POST' do |d|
        d.Say 'Welcome to Twilio support line!'
        d.Say 'To get specialized help with programmable voice press 1, '\
              'or press 2 for programmable SMS'
      end
    end.to_xml
  end
end
