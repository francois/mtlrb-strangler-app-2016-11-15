require_relative '../../legacy/app'

Rails.application.routes.draw do
  get '/report(/:id)', to: 'reports#show'
  mount Sinatra::Application, at: "/"
end
