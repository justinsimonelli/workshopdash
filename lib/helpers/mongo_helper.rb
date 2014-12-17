require 'mongo'
require_relative '../workshop_dash'

module WorkshopDash
	class MongoHelper
		include WorkshopDash

			#exposes database to outside world
			#attr_reader :database

			def self.db
				return @db if @db
				@dbconfig = config('auth.mongodb')
				@database = @dbconfig['database']
				@db = connection.db(@database)
				@db.authenticate(@dbconfig['user'], @dbconfig['password']) unless (@dbconfig['user'].nil? || @dbconfig['user'].empty?)
				@db
			end

			private

			def self.connection
				@connection = Mongo::Connection.new(@dbconfig['host'], @dbconfig['port'])
			end

			def self.env
				Sinatra::Application.environment.to_s
			end

			def to_string
				"MongoHelper [database=#{@database}]"
			end

			private_class_method :new

		end
	end