require "sinatra"

get "/report" do
  "<h1>Reporting</h1>\n<p>Report, from Replacement app (id: none)</p>\n"
end

get "/report/:id" do
  "<h1>Reporting</h1>\n<p>Report, from Replacement app (id: #{params[:id].inspect})</p>\n"
end
