require 'rails_helper'

describe TwimlGenerator do
  describe '.generate_gather_product' do
    it 'generates twiml with say and gather nodes' do
      welcome_message = 'Welcome to Twilio support line!'
      options_message =
        'To get specialized help with programmable voice press 1, '\
        'or press 2 for programmable SMS'

      callback_url = '/call/enqueue'

      xml_string = described_class.generate_gather_product(callback_url)
      document = Nokogiri::XML(xml_string)

      gather_node = document.root.child
      first_say_node = gather_node.children.first
      last_say_node = gather_node.children.last

      expect(gather_node.name).to eq('Gather')
      expect(gather_node.attribute('numDigits').content)
        .to eq('1')
      expect(gather_node.attribute('action').content)
        .to eq(callback_url)
      expect(gather_node.attribute('method').content)
        .to eq('POST')
      expect(first_say_node.content).to eq(welcome_message)
      expect(last_say_node.content).to eq(options_message)
    end
  end
end
