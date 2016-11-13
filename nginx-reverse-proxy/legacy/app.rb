require "sinatra"

get "/" do
  <<-EOS
    <h1>Hello World</h1>
    <p>This is the Legacy app</p>
    <p>Proceed to the <a href="/report">reporting</a> section</p>
  EOS
end

get "/report" do
  "Report, from Legacy"
end
