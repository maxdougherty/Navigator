class Event < ActiveRecord::Base

	has_many :us_es_relations, dependent: :destroy
	has_many :users, through: :us_es_relations
	has_many :ss_es_relations, dependent: :destroy
	has_many :schedules, through: :ss_es_relations

	# Models are magic. All code below is unused. -Max

	# MAX_TITLE_LENGTH = 128
	# INVALID_INPUT = -1
	# SUCCESS = 1
	# NO_RECORD = -2

	# def self.new_event(title, start, finish)
	# 	if (title.length > MAX_TITLE_LENGTH) || title.nil?
	# 		return INVALID_INPUT
	# 	end
	# 	if (start < 0) || (finish < 0)
	# 		return INVALID_INPUT
	# 	end
	# 	if ((start % 100) % 60) != (start % 100) || (start % 2400) != start
	# 		return INVALID_INPUT
	# 	end
	# 	if ((finish % 100) % 60) != (finish % 100) || (finish % 2400) != finish
	# 		return INVALID_INPUT
	# 	end

	# 	event = Event.new(title: title, start_time: start, end_time: finish)
	# 	event.save
	# 	return SUCCESS
	# end

	# def self.remove_event(id)
	# 	event = Event.where(id: id)
	# 	if event.nil?
	# 		return NO_RECORD
	# 	end
	# 	Event.find(id).destroy
	# 	return SUCCESS
	# end

	# def self.edit_event(id, new_title, new_start, new_finish)
	# 	event = Event.where(id: id)
	# 	if event.nil?
	# 		return NO_RECORD
	# 	end
	# 	if (new_title.length > MAX_TITLE_LENGTH) || new_title.nil?
	# 		return INVALID_INPUT
	# 	end
	# 	if (new_start < 0) || (new_finish < 0)
	# 		return INVALID_INPUT
	# 	end
	# 	if ((new_start % 100) % 60) != (new_start % 100) || (new_start % 2400) != new_start
	# 		return INVALID_INPUT
	# 	end
	# 	if ((new_finish % 100) % 60) != (new_finish % 100) || (new_finish % 2400) != new_finish
	# 		return INVALID_INPUT
	# 	end

	# 	event = event.first
	# 	event.title = new_title
	# 	event.start_time = new_start
	# 	event.end_time = new_finish
	# 	event.save
	# 	return SUCCESS

	# end

	# def self.reset_fixture
	# 	Event.destroy_all
	# 	return 1
	# end

end
