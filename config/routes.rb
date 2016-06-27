Rails.application.routes.draw do
  root 'missed_calls#index'

  post  'call/enqueue'  => 'call#enqueue'
  get   'call/incoming' => 'call#incoming'
end
