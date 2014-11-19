require 'twilio-ruby'
load "./lib/organizer.rb"

# doesn't know of ENV vars locally :(
desc "checks the reminders in Redis through Organizer"
task :check_update_text do
	puts "*** checking, updating reminders ***"
	
	red = Redis.new(url: ENV['REDISTOGO_URL'])
	org = Organizer.new(red, ENV['REMINDER_SET_NAME'], ENV['TIME_ZONE'])
	todos = org.check_and_update_msgs

	puts "Todos: "
	puts todos

	twil = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']

	twil.account.messages.create(
		from: ENV['TWILIO_FROM_NUMBER'],
		to:   ENV['TWILIO_TO_NUMBER']
		body: "\n#{todos.join("\n")}"
		)

	puts "*** finished texting todos ***"
end
