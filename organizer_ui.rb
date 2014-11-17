require 'sinatra'
require 'rubygems'
require 'haml'
require 'redis'

load 'organizer.rb'
puts "Howd¥, setting up the Organizer."
r = Redis.new
@@org = Organizer.new(r, "myc1", "America/Denver")


# instantiate the Organizer class
get '/' do
	redirect to '/reminders' 
end

# view reminders, make new ones
get '/reminders' do
	@reminders = @@org.view_all_msgs_with_rank
	haml :reminders
end

# adding a reminder
post '/reminders' do
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

# updates the reminders as well as shows them
get '/update_reminders' do
	@todos = @@org.check_and_update_msgs

	haml :todo_now
end

__END__

@@todo_now
%p
	here's what's due now:
	- @todos.each do |td|
		%li= td
%p
	GOTO
	%a{href: '/reminders'} all reminders


@@layout
!!!
%html
	%head
		%title using Organizer class
	%body
		= yield
		%footer
			%p by Andrew


@@reminders
%p
	here's what's on your docket:
	- @reminders.each.with_index do |r, idx|
		%li
			= r
			%form{method: "POST", action: '/delete_reminder'}
				%input{type: "text", name: "rank", value: "#{idx+1}", style: "display:none"}
				%input{type: "submit", value: "X"}

%p type your new reminders here:

%form{method: "POST", action: '/reminders'}
	%label{for: "time"} Time:
	%input{type: "text", name: "time"}
	%br
	%label{for: "reminder"} Reminder:
	%input{type: "text", name: "reminder"}
	%br
	%label{for: "repeat"} Repeat Every:
	%input{type: "text", name: "repeat"}
	%br
	%input{type: "submit", value: "submit" }

%p
	GOTO
	%a{href: '/todo_now'} look @ what is due
	|
	%a{href: '/update_reminders'} look @ what is due and update

