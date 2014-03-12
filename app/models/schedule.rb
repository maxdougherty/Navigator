class Schedule < ActiveRecord::Base

	has_many :us_ss_relations, dependent: :destroy
	has_many :users, through: :us_ss_relation
	has_many :ss_es_relations, dependent: :destroy
	has_many :events, through: :ss_es_relations #, order: [:start_time, :end_time]


	# # Models are magic. All code below is unused. -Max

	# MAX_TITLE_LENGTH = 128
	# SUCCESS = 1
	# INVALID_INPUT = -1
	# NO_RECORD = -2

	# TODO: Determine removal of "self."
	# def self.new_schedule(title, day, start, finish) 
	# 	if (title.length > MAX_TITLE_LENGTH) || title.nil?
	# 		return INVALID_INPUT
	# 	end
	# 	if (day < 0) || (start < 0) || (finish < 0)
	# 		return INVALID_INPUT
	# 	end
	# 	if ((day % 7) != day)
	# 		return INVALID_INPUT
	# 	end
	# 	if ((start % 100) % 60) != (start % 100) || (start % 2400) != start
	# 		return INVALID_INPUT
	# 	end
	# 	if ((finish % 100) % 60) != (finish % 100) || (finish % 2400) != finish
	# 		return INVALID_INPUT
	# 	end

	# 	schedule = Schedule.new(title: title, day: day, start_time: start, 
	# 		end_time: finish, has_events: false, num_events: 0)
	# 	schedule.save
	# 	return SUCCESS

	# end

	# def self.remove_schedule(id)
	# 	schedule = Schedule.where(id: id)
	# 	if schedule.nil?
	# 		return NO_RECORD
	# 	end

	# 	Schedule.find(id).destroy
	# 	return SUCCESS

	# end

	# def self.edit_schedule(id, new_title, new_day, new_start, new_finish)
	# 	if (new_title.length > MAX_TITLE_LENGTH) || title.nil?
	# 		return INVALID_INPUT
	# 	end
	# 	if (new_day < 0) || (new_start < 0) || (new_finish < 0)
	# 		return INVALID_INPUT
	# 	end
	# 	if ((new_day % 7) != new_day)
	# 		return INVALID_INPUT
	# 	end
	# 	if ((new_start % 100) % 60) != (new_start % 100) || (new_start % 2400) != new_start
	# 		return INVALID_INPUT
	# 	end
	# 	if ((new_finish % 100) % 60) != (new_finish % 100) || (new_finish % 2400) != new_finish
	# 		return INVALID_INPUT
	# 	end

	# 	schedule = Schedule.where(id: id)
	# 	if schedule.nil?
	# 		return NO_RECORD
	# 	end
	# 	schedule = schedule.first
	# 	schedule.title = new_title
	# 	schedule.day = new_day
	# 	schedule.start_time = new_start
	# 	schedule.end_time = new_finish
	# 	schedule.save
	# 	return SUCCESS

	# end

	# def self.reset_fixture
	# 	User.destroy_all
	# 	return 1
	# end




end
