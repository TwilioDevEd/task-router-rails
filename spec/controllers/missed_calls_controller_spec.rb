require 'rails_helper'

RSpec.describe MissedCallsController, type: :controller do
  describe 'GET #index' do
    it 'assigns all missed_calls as @missed_calls' do
      missed_call = MissedCall.create(
        selected_product: 'voice',
        phone_number: '+12345678'
      )
      get :index
      expect(assigns(:missed_calls)).to eq([missed_call])
    end
  end
end
