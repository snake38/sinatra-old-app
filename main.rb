require 'rubygems'
require 'sinatra'
require 'data_mapper'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/database.db")

class User
   include DataMapper::Resource
   
   property :id,           Serial
   property :username,     String
   property :password,     String
   property :mail,         String
   property :role,		   String,	:default => 'user'
   property :registertime, DateTime
end

class News
  include DataMapper::Resource
  
  property :id,       Serial
  property :title,    String
  property :text,     Text
  property :author,   String
  property :date,     DateTime
end

enable :sessions

helpers do
  def logged?
    session["user_id"] != nil
  end
end

get '/' do
  @title = "Home"
  erb :index
end
  
get '/login/' do
  if logged?
    redirect '/'
  else
    erb :login
  end
end

post '/login/' do
   user = User.first(:username => params[:username], :password => params[:pass])
   if user
      session["user_id"] ||= user.id
      session["user_name"] ||= user.username
      session["role"] ||= user.role
      redirect '/'
   else
      erb "Not logged!"
   end
end

get '/logout/' do
  session.clear
  redirect '/'
end

get '/register/' do
  if logged?
    redirect '/'
  else
    erb :register
   end
end

post '/register/' do
   if !params[:mail].match(/\A([^@\s<>'"]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i)
      erb "Wrong e-mail"
   elsif User.first(username: params[:username])
      erb "Username is occupied"
   elsif User.first(mail: params[:mail])
      erb "E-mail is occupied"
   elsif params[:username].length < 2
      erb "Username is too short"
   elsif params[:pass].length < 5
      erb "Password is too short"
   elsif params[:pass] != params[:passcheck]
      erb "Passwords do not match"
   else
      user = User.new(:username => params[:username], :password => params[:pass], :mail => params[:mail], :registertime => Time.now)
      user.save
      session["user_id"] = user.id
      session["user_name"] = user.username
      session["role"] = user.role
      redirect '/'
   end
end

get '/users/' do
   @users = Users.all(:limit => 20, :order => [:id.desc])
   erb :users
end

get '/user/:id/' do
  @user = Users.first(:id => params[:id])
  erb :user
end

get '/user/:id/delete' do
	if logged?
	  if params[:id] != session["user_id"]
		user = Users.first(:id => params[:id])
		if user != nil
		  user.destroy
		  redirect '/users/'
		else
		  erb "User not exist"
		end
	  else
		erb "You can't delete yourself"
		redirect '/user/#{params[:id]}/'
	  end
	else
		redirect '/user/#{params[:id]}/'
	end
end

get '/news/' do
  @news = News.all(:limit => 20, :order => [:id.desc])
  erb :newsa
end

get '/news/create/' do
  erb :createnews
end

post '/news/create/' do
  if params[:title].length < 5
    erb "Title is too short"
  elsif params[:text].length < 10
    erb "Text is too short"
  else
    news = News.new(:title => params[:title], :text => params[:text], :author => session["user_id"], :date => Time.now)
    news.save
    redirect '/news/'
  end
end

get '/news/:nid/' do
  @news = News.first(:id => params[:nid])
  @author = Users.first(:id => @news.author.to_i)
  erb :news
end

get '/news/:nid/delete/' do
	if logged?
		news = News.first(:id => params[:nid])
		if news != nil
			news.destroy
			redirect '/news/'
		else
			erb "News not exist"
		end
	else
		redirect '/news/#{params[:nid]}'
	end
end

not_found do
   erb "Page not found!"
end

DataMapper.auto_upgrade!
