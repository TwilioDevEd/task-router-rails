Rails.application.routes.draw do
  root 'missed_calls#index'

  get  'call/enqueue'  => 'call#enqueue'
  post 'call/incoming' => 'call#incoming'
end
