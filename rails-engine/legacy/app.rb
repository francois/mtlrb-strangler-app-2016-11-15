require "sinatra"

if ENV["SINATRA_RUN"] == "1" then
  enable :run
else
  disable :run
end

get "/" do
  <<-EOS
    <h1>Hello World</h1>
    <p>This is the Legacy app</p>
    <p>Proceed to the <a href="/report">reporting</a> section</p>
  EOS
end

get "/report" do
  sleep 6
  "Report, from Legacy"
end
