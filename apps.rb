# frozen_string_literal: true

require "sinatra"
require "sinatra/reloader"
require "csv"

enable :method_override

before do
  cache_control :no_chache
end

["/", "/memos"].each do |route|
  get route do
    @datas = CSV.read("memo_data.csv").select { |data| !data.empty? }
    erb :index
  end
end

get "/memos/new" do
  erb :new
end

post "/memos/new" do
  @id = CSV.read("memo_data.csv").length
  @title = params[:title]
  @content = params[:content]

  CSV.open("memo_data.csv", "a") do |memo|
    memo << [@id, @title, @content.gsub(/(\r\n|\r|\n)/, "<br>")]
  end
  redirect "/memos/#{@id}"
end

get "/memos/:id" do
  data = CSV.read("memo_data.csv")
  @id = params[:id].to_i
  @title = data[@id][1]
  @content = data[@id][2]
  erb :show
end

delete "/memos/:id" do
  @id = params[:id].to_i
  data = CSV.read("memo_data.csv")

  data[@id].clear
  File.open("memo_data.csv", "w") do |f|
    data.each { |a| f.puts(a.join(",")) }
  end

  redirect "/memos"
end

get "/memos/:id/edit" do
  data = CSV.read("memo_data.csv")
  @id = params[:id].to_i
  @title = data[@id][1]
  @content = data[@id][2].gsub(/<br>/, "\n")
  erb :edit
end

patch "/memos/:id/edit" do
  data = CSV.read("memo_data.csv")
  @id = params[:id].to_i
  @title = params[:title]
  @content = params[:content]

  data[@id] = [@id, @title, @content.gsub(/(\r\n|\r|\n)/, "<br>")]
  File.open("memo_data.csv", "w") do |f|
    data.each { |a| f.puts(a.join(",")) }
  end

  redirect "/memos/#{@id}"
end
