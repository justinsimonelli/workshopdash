class Standups < WorkshopDash::BaseWidget

	new("standups").schedule_event do
		results = MongoHelper.db['standups'].find()
		standups_list = results.map do |row|
			row = {
				:name => row['name'],
				:startTime => row['startTime'],
				:endTime => row['endTime'],
				:frequency => row['frequency']
			}
		end
		{items: standups_list}
	end
end