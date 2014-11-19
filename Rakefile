load "./lib/organizer.rb"

# doesn't know of ENV vars :(
desc "checks the reminders in Redis through Organizer"
task :check_update_text do
	puts "checking, updating reminders"
	
	red = Redis.new(url: ENV['REDISTOGO_URL'])
	org = Organizer.new(red, ENV['REMINDER_SET_NAME'], ENV['TIME_ZONE'])
	todos = org.check_and_update_msgs

	puts "Todos: "
	puts todos

	# POST to Twiml endpoint IF not ""
	twiml = Twilio::TwiML::Response.new do |r|
		r.Message "\n#{todos.join("\n")}"
	end
	twiml.text
end
