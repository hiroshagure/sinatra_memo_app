# frozen_string_literal: true

require "sinatra"
require "sinatra/reloader"
require "csv"

class Memo
  FILE = "memo_data.csv"

  attr_reader :data, :title, :content

  def initialize(id = 0)
    @data = CSV.read(FILE)
    @title = @data[id][1]
    @content = @data[id][2]
  end

  def all_data
    data.select { |record| !record.empty? }
  end

  def format_content
    content.gsub(/<br>/, "\n")
  end

  def self.insert(id, title, content)
    CSV.open(FILE, "a") do |data|
      data.flock(File::LOCK_EX)
      data << [id, title, content.gsub(/(\r\n|\r|\n)/, "<br>")]
      data.flock(File::LOCK_UN)
    end
  end

  def self.update(id, title, content)
    data = CSV.read(FILE)
    data[id] = [id, title, content.gsub(/(\r\n|\r|\n)/, "<br>")]
    write_file(data)
  end

  def self.delete(id)
    data = CSV.read(FILE)
    data[id].clear
    write_file(data)
  end

  private
    def self.write_file(data)
      File.open(FILE, "w") do |file|
        file.flock(File::LOCK_EX)
        data.each { |record| file.puts(record.join(",")) }
        file.flock(File::LOCK_UN)
      end
    end
end

before do
  cache_control :no_chache
end

["/", "/memos"].each do |route|
  get route do
    memo = Memo.new
    @data = memo.all_data
    erb :index
  end
end

post "/memos" do
  memo = Memo.new
  id = memo.data.length
  title = params[:title]
  content = params[:content]

  Memo.insert(id, title, content)
  redirect "/memos/#{id}"
end

get "/memos/new" do
  erb :new
end

get "/memos/:id" do
  @id = params[:id].to_i
  memo = Memo.new(@id)
  @title = memo.title
  @content = memo.content
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
  @content = memo.format_content
  erb :edit
end
