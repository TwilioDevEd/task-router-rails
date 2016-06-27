require 'rails_helper'

describe TwimlGenerator do
  describe '.generate_gather_product' do
    it 'generates twiml with say and gather nodes' do
      welcome_message = 'Welcome to the Twilio support line!'
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

  describe '.generate_task_enqueue' do
    workflow_sid     = 'WWXXXXXXXX'
    selected_product = 'ProgrammableSMS'

    before do
      expect(WorkspaceInfo).to receive_message_chain(:instance, :workflow_sid)
        .and_return(workflow_sid)
    end

    it 'generates twiml with enqueue and task nodes' do
      xml_string = described_class.generate_task_enqueue(selected_product)
      document   = Nokogiri::XML(xml_string)

      enqueue_node = document.root.child
      task_node    = enqueue_node.child

      expect(enqueue_node.name).to eq('Enqueue')
      expect(enqueue_node.attribute('workflowSid').content)
        .to eq(workflow_sid)

      expect(task_node.name).to eq('Task')
      expect(task_node.content)
        .to eq("{\"selected_product\": \"#{selected_product}\"}")
    end
  end
end
