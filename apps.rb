# frozen_string_literal: true

require "sinatra"
require "sinatra/reloader"
require "pg"

class Memo
  @@connection = PG.connect(dbname: "memoapp")
  attr_reader :id, :title, :content

  def initialize(id)
    result = @@connection.exec("SELECT * FROM memos WHERE id = #{id}")
    @title = result[0]["title"]
    @content = result[0]["content"]
  end

  def format_content
    content.gsub(/\r\n/, "<br>")
  end

  def self.all_data
    result = @@connection.exec("SELECT * FROM memos ORDER BY id DESC")
    result.values
  end

  def self.insert(title, content)
    @@connection.exec("INSERT INTO memos (title, content) VALUES ('#{title}', '#{content}')")
    result = @@connection.exec("SELECT id FROM memos WHERE id = (SELECT max(id) FROM memos)")
    result[0]["id"]
  end

  def self.update(id, title, content)
    @@connection.exec("UPDATE memos SET title = '#{title}', content = '#{content}' WHERE id = #{id}")
  end

  def self.delete(id)
    @@connection.exec("DELETE FROM memos WHERE id = #{id}")
  end
end

before do
  cache_control :no_chache
end

["/", "/memos"].each do |route|
  get route do
    @data = Memo.all_data
    erb :index
  end
end

post "/memos" do
  title = params[:title]
  content = params[:content]

  id = Memo.insert(title, content)
  redirect "/memos/#{id}"
end

get "/memos/new" do
  erb :new
end

get "/memos/:id" do
  @id = params[:id].to_i
  memo = Memo.new(@id)
  @title = memo.title
  @content = memo.format_content
  erb :show
end

patch "/memos/:id" do
  id = params[:id].to_i
  title = params[:title]
  content = params[:content]

  Memo.update(id, title, content)
  redirect "/memos/#{id}"
end

delete "/memos/:id" do
  id = params[:id].to_i
  Memo.delete(id)
  redirect "/memos"
end

get "/memos/:id/edit" do
  @id = params[:id].to_i
  memo = Memo.new(@id)
  @title = memo.title
  @content = memo.content
  erb :edit
end
