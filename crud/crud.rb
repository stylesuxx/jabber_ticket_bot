# This class represents the CRUD interface to the database.
class CRUD
	
	# Initializes the ticket Crud
	#
	# +database+:: A database handler
	# +table+:: The table to operate on
	# +validFields+:: An array of valid fields for this table
	def initialize database, table, validFields
		@dbh = database
		@table = table
		@validFields = validFields
	end

	# Adds a new record to the database.
	#
	# +fiedls+:: A Hashmap with the fields and values from which to create a new record
 	#
	# Returns the ID of the newly created record or nil in case of error.
	def create fields
		fields.delete_if {|key, value| !@validFields.include? key}
		selection = ""
		values = ""

		fields.each do |key, value|
			selection += "#{key}, "
			values += "'#{value}', "
		end

		selection = selection[0..-3]
		values = values[0..-3]

		begin
			query = "INSERT INTO #{@table}(#{selection}) VALUES(#{values})"

			@dbh.query query	
			@dbh.last_id
		rescue => e
			puts "Error: #{e.error}"
			nil
		end
	end

	# Read information about a ticket from the database
	#
	# +fields+:: An array with the field values to retrieve
	# +primaryFilter+:: This is the main filter for the query. It expects an array with the first value being a field in the database and the second value being the value to filter for on this field
	# +orFilter+:: A Hashtable where the keys are the fields and the values are the values to filter for
	# +andFilter+:: A Hashtable where the keys are the fields and the values art the values to filter for
	#
	# Returns an array with an entry for each matching ticket and the requested fields or nil in case of error.
	def read fields, primaryFilter = nil, orFilter = nil, andFilter = nil, notFilter = nil
		fields.delete_if {|key, value| !@validFields.include? key}

		selection = fields.count > 1 ? fields.join(", ") :	fields[0]
		
		begin
			query = "SELECT #{selection} FROM #{@table}"

			if primaryFilter
				query += " WHERE #{primaryFilter[0]}='#{primaryFilter[1]}'"

				if orFilter
					orFilter.each {|key, value| query += " OR #{key}='#{value}'"}
				end

				if andFilter
					andFilter.each {|key, value| query += " AND #{key}='#{value}'"}
				end

				if notFilter
					notFilter.each {|key, value| query += " AND NOT #{key}='#{value}'"}
				end
			end

			result = @dbh.query query
			tickets = Array.new()

			result.each {|row| tickets.push row}
			tickets
		rescue => e
			puts "Error: #{e.error}"
			nil
		end
	end

	# Updates a record in the databas
	#
	# +fields+:: A Hashtable where the keys are the fields in the table and the values are the fields new values
	# +primaryFilter+:: This is the main filter for the query. It expects an array with the first value being a field in the database and the second value being the value to filter for on this field
	# +orFilter+:: A Hashtable where the keys are the fields and the values are the values to filter for
	# +andFilter+:: A Hashtable where the keys are the fields and the values art the values to filter for
	#	+notFilter+:: A Hashtable where the keys are the fields and the values art the values to filter for
	#
	# Returns true if the ticket was updated, false otherwise.
	def update fields, primaryFilter = nil, orFilter = nil, andFilter = nil, notFilter = nil
		fields.delete_if {|key, value| !@validFields.include? key}

		if fields.count > 0
			begin
				query = "UPDATE #{@table} SET"
				fields.each {|key, value| query += " #{key}='#{value}',"}
				timestamp = Time.now
				query += "updated='#{timestamp}'"

				if primaryFilter
					query += " WHERE #{primaryFilter[0]}='#{primaryFilter[1]}'"

					if orFilter
						orFilter.each {|key, value| query += " OR #{key}='#{value}'"}
					end

					if andFilter
						andFilter.each {|key, value| query += " AND #{key}='#{value}'"}
					end

					if notFilter
						notFilter.each {|key, value| query += " AND NOT #{key}='#{value}'"}
					end
				end

				@dbh.query query
				true
			rescue => e
				puts "Error: #{e.error}"
				false
			end
		end
	end

	# Deletes a record from the database.
	#
	# +field+:: An array with the first value being the field and the second one the value to delete
	#
	# Returns true if there were matching records and they were deleted, false in case there were no matching record and nil in case of mysql error.
	def delete field
		begin
			ticket = read ['id'], field
			if ticket.count > 0
				@dbh.query "DELETE FROM #{@table} WHERE #{field[0]}='#{field[1]}'"
				true
			else
				false
			end
		rescue Mysql::Error => e
			puts "Error: #{e.error}"
			nil
		end
	end

end