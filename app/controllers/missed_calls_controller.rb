class MissedCallsController < ApplicationController
  def index
    @missed_calls = MissedCall.all
  end
end
