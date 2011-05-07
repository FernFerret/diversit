require 'rubygems'
require 'bundler'
require 'digest/sha1'

Bundler.require

require 'config/database'
require 'helpers/sinatra'

enable :sessions

# App modeled after:
# https://github.com/daddz/sinatra-dm-login/

## PATHS

get '/' do
  @question = Question.first(:forday => Date.today) # question of the day
  @users = User.all(:order => :username)            # list of all useres
  @u = session[:user]
  haml :index
end

get '/questions' do
  # @questions = Question.all(:forday.lt => Date.today, :order => :forday.desc) # list all past questions in desc. order
  @questions = Question.all(:order => :forday.desc) # list all questions in desc. order
  haml :question_archive
end

get '/addquestion' do
  redirect '/register' unless logged_in?

  haml :question_add
end

post '/addquestion' do
  redirect '/register' unless logged_in?

  # insert question into database
  @question = Question.create(:body => params[:question], :type => params[:type], :timestamp => Time.now, :forday => Date.today)
  Choice.create(:body => params[:choice1], :question => @question)
  Choice.create(:body => params[:choice2], :question => @question)
  Choice.create(:body => params[:choice3], :question => @question)
  Choice.create(:body => params[:choice4], :question => @question)

  haml :question_success
end

get '/question/:id' do
  @question = Question.get(params[:id])
  if @question
    @responses = @question.response.all(:parent_id => nil) # get top-level responses
  end

  haml :question
end

post '/question/:id' do
  redirect '/register' unless logged_in?

  @question = Question.get(params[:id])
  if @question
    @responses = @question.response.all(:parent_id => nil) # get top-level responses
  end
  @body = params[:response]
  @choice = params[:choice]
  @user = User.get(session[:user].id)
  @timestamp = Time.now

  if params[:response].to_s.length > 0 and @question.forday == Date.today # if response is not null and the question is active
    Response.create(:body => @body, :choice => @choice, :timestamp => @timestamp, :user => @user, :question => @question)
  end

  haml :question
end

get '/comment/:qid/:rid' do
  redirect '/register' unless logged_in?

  haml :comment_add
end

post '/comment/:qid/:rid' do
  redirect '/register' unless logged_in?

  parent = Response.get(params[:rid])
  question = Question.get(params[:qid])

  if params[:comment].length > 0 and question.forday == Date.today
    # create new comment as a child of its parent
    parent.children.create(:body => params[:comment], :choice => -1, :timestamp => Time.now, :user => User.get(session[:user].id), :question => question)
  end

  # redirect to question page
  redirect '/question/' + question.id.to_s
end

get '/register' do
  haml :register
end

post '/register' do
  # assert registration data validity
  valid = (
    params['username'] != '' and
    params['firstname'] != '' and
    params['lastname'] != '' and
    params['password'] != '' and
    params['pconfirm'] != '' and
    params['dob'] != '' and
    params['password'] == params['pconfirm'])

  if not valid
    session[:error] = 'Please ensure that your registration input is valid.'
    # redirect back to same page with error messages in header
    redirect '/register'
  end

  # create user
  u = User.new
  u.username = params['username']
  u.password = params['password']
  u.dob = params['dob']
  u.firstname = params['firstname']
  u.lastname = params['lastname']
  u.save

  # log in user
  session[:user] = User.auth(params["username"], params["password"])

  redirect '/'
end

get '/login' do
  haml :login
end

post '/login' do
  session[:user] = User.auth(params["username"], params["password"])

  session[:notice] = "Logged in successfully!"

  redirect '/'
end

get '/logout' do
  session[:user] = nil
  session[:notice] = "Logged out successfully!"

  redirect '/'
end

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end
