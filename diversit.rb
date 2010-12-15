require 'rubygems'
require 'sinatra'
require 'config/database'
require 'helpers/sinatra'
require 'haml'

enable :sessions

# App modeled after:
# https://github.com/daddz/sinatra-dm-login/

## PATHS

get '/' do
  @question = Question.first(:forday => Date.today)
  @u = session[:user]
  @users = User.all :order=>[:username]
  haml :index
end

get '/questions' do
  @questions = Question.all(:forday.lt => Date.today, :order => :forday.desc)
  haml :question_archive
end

get '/addquestion' do
  haml :question_add
end

post '/addquestion' do
  @question = Question.create(:body=>params[:question], :type=>'free', :timestamp=>Time.now)
  haml :question_success
end

get '/addcomment/:qid/:rid' do
  if logged_in?
    haml :comment_add
  else
    redirect '/register'
  end
end

post '/addcomment/:qid/:rid' do
  if logged_in?
    parent = Response.get(params[:rid])
    question = Question.get(params[:qid])
    if params[:comment].to_s.length > 0 and question.forday == Date.today
      parent.children.create(:body=>params[:comment], :user=>User.get(session[:user].id), :timestamp=>Time.now, :question=>question)
    end
    # @comment = Comment.create(:body=>params[:comment], :user=>User.get(session[:user].id), :answer=>ans)
    redirect '/question/'+question.id.to_s
  else
    redirect '/register'
  end
  haml :comment_add
end

get '/question/:id' do
  if @question = Question.get(params[:id])
    @answers = @question.response.all(:parent_id => nil)
  end
  haml :question
end

post '/question/:id' do
  if logged_in?
    @question = Question.get(params[:id])
    @answers = @question.response.all(:parent_id => nil)
    @body = params[:response]
    @user = User.get(session[:user].id)
    @timestamp = Time.now
    if params[:response].to_s.length > 0 and @question.forday == Date.today
      Response.create(:body=>params[:response], :user=>User.get(session[:user].id), :timestamp=>Time.now, :question=>@question)
    end
    haml :question
  else
    redirect '/register'
  end
end

get '/register' do
  haml :register
end

post '/register' do
  if params['email'] != '' and params['password'] != '' and params['password'] == params['pconfirm'] and params['bdate'] != '' and params['first'] != '' and params['last'] != ''
    u = User.new
    u.username = params['email']
    u.password = params['password']
    u.dob = params['bdate']
    u.firstname = params['first']
    u.lastname = params['last']
    u.save
    session[:user] = User.auth(params["email"], params["password"])
    redirect '/'
  end
end

get '/login' do
  haml :login
end

post '/login' do
  session[:user] = User.auth(params["email"], params["password"])
  redirect '/'
end

get '/logout' do
  session[:user] = nil
  flash("Logout successful")
  redirect '/'
end

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end
