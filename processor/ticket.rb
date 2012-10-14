require './crud/ticket'

# The ticket processor is responsible for handling all requests that use the Ticket Crud
class TicketProcessor

	# Constructor
	#
	# +crud+:: The ticket CRUD
	def initialize crud
		@tickets = crud
	end

  # A new ticket is always added with status new and are not assigned to anyone
  #
  # Returns the id of the newly created ticket.
	def add pid, title, description, cid, tracker
		puts "In the processor: #{pid}"
		@tickets.create Hash[
			'pid' => pid, 
			'title' => title, 
			'description' => description,
			'creator' => cid, 
			'tracker' => tracker,
			'status' => 'new',
			'assigned' => '-1']
	end

	# Get all new tickets that are not assigned to anyone yet
	#
	# Returns an Array with all unasigned tickets.
	def getNew
		@tickets.read ['id', 'pid', 'title', 'description', 'tracker', 'creator', 'created'], ['status', 'new'], nil, nil, nil
	end

	# Delete a ticket from the database
	#
	# +id+:: The id of the ticket to delete
	def delete id
		@tickets.delete ['id', id]
	end

	# Checks if a ticket is already assigned
	#
	# +id+:: Ticket id to check for assignment
	#
	# Returns true if the ticket is assigned, false otherwise.
	def assigned? id
		assigned = @tickets.read ['assigned'], ['id', id], nil, nil, nil
		assigned[0]['assigned'] > 0
	end

	# Checks if the requestet ticket exists in the database
	#
	# +id+:: Ticket id to check for existence
	#
	# Returns true if the ticket exists, false otherwise.
	def exists? id
		tickets = @tickets.read ['id'], ['id', id], nil, nil, nil
		tickets.count > 0
	end

	# Assign a ticket to a user
	#
	# +id+:: The ticket id the user should be assigned to
	# +uid+:: The user ID that should be assigned to the ticket
	#
	# Returns the ID of the updated ticket or nil in case of error.
	def assign id, uid
		@tickets.update Hash["assigned" => uid, 'status' => 'assigned'], ['id', id]
	end

	# Get all assigned (non closed) tickets by user id
	#
	# +uid+:: The ID of the user whos tickets to look up
	#
	# Returns an array of tickets assigned to the user.
	def getAssigned uid
		@tickets.read ['id', 'pid', 'title', 'description', 'tracker', 'creator', 'created', 'status'], ['assigned', uid], nil, nil, Hash["status" => "closed"]
	end

	# Get a nice formatted list.
	# TODO: The generation of the text shoud be done in incomming.rb
	def getNiceList
		tickets = @tickets.read ['machinename', 'title', 'description']

		output = "Tickets:"
		tickets.each do |row|
			output += "\n#{row['title']} \(#{row['machinename']}\)\n"
			output += "#{row['description']}\n"
			output += "-------------------------------------------"
		end
		output
	end

	# Get a list of all tickets.
	#
	# +fields+:: Fields to return from ticket table
	#
	# Returns the matching rows from the ticket table.
	def getList fields = ["*"]
		puts "here"
		tickets = @tickets.read fields
		puts "here jjj"
		output = "Projects:\n"

		tickets.each do |row|
			output += "| "
			row.each do |cell|
			 output += "#{cell[1]} | "
			end
			output += "\n"
		end
		output
	end

	#def unassign tid, nick
	#end

	#def updateStatus tid, status
	#end

	#def close tid
	#end

	#def setWatcher tid, nick
	#end

	#def unsetWatcher tid, nick
	#end

end