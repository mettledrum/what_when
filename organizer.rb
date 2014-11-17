# by Andrew Hoyle

require 'json'
require 'redis'
require 'tzinfo' # doesn't convert %Z to local :(
require 'securerandom'
require 'active_support'
require 'active_support/core_ext'

# scheduler using the redis sorted set under the hood
# check_and_update_msgs could be run with a cron job
# attach the add_msg to an endpoint!
class Organizer
	def initialize(redis_cli, set_name, time_zone_name="UTC")
		@rc = redis_cli
		@name = set_name
		update_time_zone_info(time_zone_name)
	end

	def update_time_zone(time_zone_name)
		@tz = TZInfo::Timezone.get(time_zone_name)
		@tz_name = time_zone_name
	end

	# finds any todos, removes them from redis, updates recurrences
	def check_and_update_msgs
		todos = todo_msgs
		del_msgs_by_time(find_latest_time(todos))
		add_next_ocurrences(todos) # add another if recurring
		pretify_msgs(todos)
	end

	def add_msg(msg, user_date_time, interval=nil)
		utc_time = to_utc(to_date_time(user_date_time))
		validate_future(utc_time) # TODO
		validate_interval(interval) if not interval.nil?
		json_string = jsonify_msg(msg, utc_time, interval)

		insert_into_redis(utc_time, json_string)
	end

	# user-readable message list
	# TODO: display the rank for deletion ease
	def view_all_msgs_with_rank
		add_rank(pretify_msgs(all_msgs))
	end

	def delete_by_rank(rank)
		# TODO: validate within range
		@rc.zremrangebyrank(@name, rank-1, rank-1)
	end

private

	def add_rank(msgs)
		msgs.map.with_index { |msg, i| "#{i+1}) #{msg}" }
	end

	def insert_into_redis(utc_time, json_string)
		# zset score is the epoch in secs
		@rc.zadd(@name, utc_time.to_i, json_string)
	end

	def validate_future(utc_time)
	end

	# add interval to score and resave in redis
	def add_next_ocurrences(redis_response)
		redis_response.map do |res|
			interval = extract_recurrences(res)

			if not interval.nil?
				msg = extract_msg(res)
				old_time_in_secs = res[1]
				new_time_in_secs = old_time_in_secs + 1.send(interval)
				new_time = secs_to_local_time(new_time_in_secs)
				json_string = jsonify_msg(msg, new_time, interval)

				insert_into_redis(new_time, json_string)
			end
		end
	end

	def validate_interval(interval)
		interval.downcase!
		valid_intervals = %w[year month week day hour]
		raise "invalid time interval: #{interval}" unless valid_intervals.include?(interval)
	end

	def jsonify_msg(msg, time, interval)
		{
			message: msg, 
			uuid: uuid_stamp, 
			recur_every: interval, 
			time: time
		}.to_json
	end

	def pretify_msgs(redis_response)
		redis_response.map do |res| 
			time = secs_to_local_formatted_time(res[1])
			interval = extract_recurrences(res)
			msg = extract_msg(res)
			if interval.nil?
				"#{time}: #{msg}"
			else
				"#{time}: #{msg} every: #{interval}"
			end
		end
	end

	def extract_msg(redis_response)
		JSON.parse(redis_response[0])['message']
	end

	def extract_recurrences(redis_response)
		JSON.parse(redis_response[0])['recur_every']
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

	# get array of json msgs with scores
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

	def secs_to_local_time(secs)
		Time.at(secs).utc.in_time_zone(@tz_name).to_time
	end

	def now
		Time.now
	end
end
