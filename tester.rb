# run this badboy in irb to test... change the 

load 'organizer.rb'

name_of_set = "#{SecureRandom.uuid}_set"

r = Redis.new
o = Organizer.new(r, name_of_set, "America/Denver")
o.add_msg("eat healthy", "11/16/14 8:13 AM", "hour")
o.check_and_update_msgs
