Rails.application.routes.draw do
  root 'missed_calls#index'

  post 'call/enqueue', to: 'call#enqueue'
  post 'call/incoming', to: 'call#incoming'
  post 'assignment', to: 'callback#assignment'
  post 'events', to: 'callback#events'
  post 'message/incoming', to: 'message#incoming'
end
