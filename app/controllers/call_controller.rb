class CallController < ApplicationController
  def enqueue
    digits = params['Digits']
    selected_product = digits == '1' ? 'ProgrammableVoice' : 'ProgrammableSMS'

    twiml = TwimlGenerator.generate_task_enqueue(selected_product)

    render xml: twiml
  end

  def incoming
    twiml = TwimlGenerator.generate_gather_product(call_incoming_path)

    render xml: twiml
  end
end
