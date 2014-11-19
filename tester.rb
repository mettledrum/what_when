# run these lines in irb to test the Organizer

load 'organizer.rb'

r = Redis.new
o = Organizer.new(r, "my_set", "America/Denver")
o.add_msg("eat healthy", "11/16/14 8:13 AM", "hour")
o.view_all_msgs_with_rank
o.check_msgs
o.check_and_update_msgs