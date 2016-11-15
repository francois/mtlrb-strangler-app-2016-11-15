require_relative '../../legacy/app'

Rails.application.routes.draw do
  get '/report(/:id)', to: 'reports#show'

  # Keep this line last, as this will handle anything
  # that is not explicitly handled by the Rails application
  mount Sinatra::Application, at: "/"
end
