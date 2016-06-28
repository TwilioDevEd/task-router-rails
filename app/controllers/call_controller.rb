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
end
