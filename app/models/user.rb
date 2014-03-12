class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable,
		:recoverable, :rememberable, :trackable, :validatable

	has_many :us_ss_relations, dependent: :destroy
	has_many :schedules, through: :us_ss_relations  #, order: [:day, :start_time]
	has_many :us_es_relations, dependent: :destroy
	has_many :events, through: :us_es_relations #, order: [:start_time, :end_time]

end
