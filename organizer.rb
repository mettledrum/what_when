# by Andrew Hoyle

require 'redis'
require 'tzinfo' # doesn't convert %Z to local :(
require 'securerandom'
require 'active_support'
require 'active_support/core_ext'

# scheduler using the redis sorted set under the hood
# check_msgs could be run with a cron job
# attach the add_msg to an endpoint!
class Organizer
	def initialize(redis_cli, set_name, time_zone_name="UTC")
		@rc = redis_cli
		@name = set_name
		update_time_zone_info(time_zone_name)
	end

	def update_time_zone_info(time_zone_name)
		@tz = TZInfo::Timezone.get(time_zone_name)
		@tz_name = time_zone_name
	end

	# finds any todos, removes them from redis
	def check_msgs
		todos = todo_msgs
		del_msgs_by_time(find_latest_time(todos))
		pretify_msgs(todos)
	end

	# zscore is the epoch in secs
	def add_msg(msg, user_date_time)
		formatted_time = to_utc(to_date_time(user_date_time))
		@rc.zadd(@name, formatted_time.to_i, "#{uuid_stamp}: #{msg}")
	end

	# user-readable message list
	def view_all_msgs
		pretify_msgs(all_msgs)
	end

private

	def pretify_msgs(msgs)
		msgs.map { |m| "#{secs_to_local_formatted_time(m[1])}#{clean_msg(m[0])}" }
	end

	# search for first colon, slice off uuid
	def clean_msg(msg)
		cut_idx = msg =~ /:/
		msg[cut_idx..-1]
	end

	# return msgs with times in past or now
	def todo_msgs
		freeze_time_secs = now.to_i
		todos = []

		all_msgs.each do |msg|
			if msg[1] <= freeze_time_secs
				todos << msg
			end
		end
		todos
	end

	# get array of msgs with scores
	def all_msgs
		@rc.zrange(@name, 0, -1, {withscores: true})
	end

	# remove all msgs with scores LT max
	def del_msgs_by_time(latest_time)
		@rc.zremrangebyscore(@name, 0, latest_time)
	end

	# finds most recent time for deletion
	def find_latest_time(msgs)
		times = []
		msgs.each do |msg|
			times << msg[1]
		end
		times.max
	end

	# uniqueness for set string
	def uuid_stamp
		SecureRandom.uuid
	end

	def to_date_time(user_input_date_time)
		# "1/9/14 1:01 PM"
		DateTime.strptime(user_input_date_time, "%m/%d/%y %l:%M %p")
	end

	def to_utc(date_time)
		@tz.local_to_utc(date_time).to_time
	end

	def secs_to_local_formatted_time(secs)
		Time.at(secs).utc.in_time_zone(@tz_name).strftime("%m/%d/%y %-l:%M %p %Z")
	end

	def now
		Time.now
	end
end
