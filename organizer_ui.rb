require 'rubygems'
require 'sinatra'
require 'haml'
require 'redis'
require 'twilio-ruby'

load 'lib/organizer.rb'

enable :sessions

def start_organizer
	r = Redis.new(:host => ENV['REDIS_HOST'], :port => ENV['REDIS_PORT'])
	@@org = Organizer.new(r, ENV['REMINDER_SET_NAME'], ENV['TIME_ZONE'])
end

def verify_user
	redirect to '/login' unless session[:verified] == true
end

start_organizer

before /^(?!\/login)/ do
	verify_user
end

get '/login' do
	haml :login
end

post '/login' do
	if params[:password] == ENV['THE_PASSWORD']
		session[:verified] = true
	end

	verify_user
	redirect to '/reminders'
end

post '/logout' do
	session[:verified] = false
	redirect to '/login'
end

# view reminders, make new ones
get '/reminders' do
	@reminders = @@org.view_all_msgs_with_rank
	haml :reminders
end

post '/add_reminders' do
	time = params[:time]
	reminder = params[:reminder]
	repeat = params[:repeat]
	repeat = nil if repeat.empty? # guard against ""

	@@org.add_msg(reminder, time, repeat)

	redirect to '/reminders'
end

# see what is due now
get '/todo_now' do
	@todos = @@org.check_msgs

	haml :todo_now
end

post '/delete_reminder' do
	delete_me = params[:rank].to_i

	@@org.delete_by_rank(delete_me)

	redirect to '/reminders'
end
