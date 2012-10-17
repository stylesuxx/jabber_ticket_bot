require './crud/ticket'

# The ticket processor is responsible for handling all requests that use the Ticket Crud
class TicketProcessor

	# Constructor
	#
	# +crud+:: The ticket CRUD
	def initialize crud
		@tickets = crud
	end

  # A new ticket is always added with status new and are not assigned to anyone.
  #
  # Returns the id of the newly created ticket.
	def add pid, title, description, cid, tracker
		@tickets.create Hash[
			'pid' => pid, 
			'title' => title, 
			'description' => description,
			'creator' => cid, 
			'tracker' => tracker,
			'status' => 'new',
			'assigned' => '-1']
	end

	# Delete a ticket from the database.
	#
	# +id+:: The id of the ticket to delete
	def delete id
		@tickets.delete ['id', id]
	end

	# Checks if the requestet ticket exists in the database.
	#
	# +id+:: Ticket id to check for existence
	#
	# Returns true if the ticket exists, false otherwise.
	def exists? id
		tickets = @tickets.read ['id'], ['id', id], nil, nil, nil
		tickets.count > 0
	end

	# Get all new tickets that are not assigned to anyone yet.
	#
	# Returns an Array with all unasigned tickets.
	def getNew
		@tickets.read ['id', 'pid', 'title', 'tracker', 'created'], ['status', 'new']
	end

	# Checks if a ticket is already assigned.
	#
	# +id+:: Ticket id to check for assignment
	#
	# Returns true if the ticket is assigned, false otherwise.
	def assigned? id
		assigned = @tickets.read ['assigned'], ['id', id], nil, nil, nil
		assigned[0]['assigned'] > 0
	end

	# Assign a ticket to a user.
	#
	# +id+:: The ticket id the user should be assigned to
	# +uid+:: The user ID that should be assigned to the ticket
	#
	# Returns true if the ticket was updated, false otherwise.
	def assign id, uid
		@tickets.update Hash["assigned" => uid, 'status' => 'assigned'], ['id', id], nil, nil, nil
	end

	# Unassigns a ticket and sets it's status to new.
	#
	# +id+:: The id of the tickete to unassign
	#
	# Returns true if the ticket was updated, false otherwise.
	def unassign id
		@tickets.update Hash["assigned" => -1, 'status' => 'new'], ['id', id], nil, nil, nil
	end

	# Updates the status of a ticket.
	#
	# +id+:: Id of the ticket to update
	# +status+:: The status to update to
	#
	# Returns true if the ticket was updated, false otherwise.
	def updateStatus id, status
		@tickets.update Hash['status' => status], ['id', id]
	end

	# Gets the status of a ticket.
	#
	# +id+:: Id of the ticket to get the status for
	#
	# Returns the status of the ticket or nil in case of error.
	def getStatus id
		status = @tickets.read ['status'], ['id', id]
		status = status[0]['status']
	end

	# Get all assigned (non closed) tickets by user id.
	#
	# +uid+:: The ID of the user whos tickets to look up
	#
	# Returns an array of tickets assigned to the user.
	def getAssigned uid
		@tickets.read ['id', 'pid', 'title', 'tracker', 'status'], ['assigned', uid], nil, nil, Hash["status" => "closed"]
	end

	# Get the details for a ticket.
	#
	# +id+:: The ID of the ticket to look the details up for
	#
	# Returns a ticket's details.
	def getDetails id
		ticket = @tickets.read ['id', 'pid', 'title', 'description', 'tracker', 'creator', 'created', 'status'], ['id', id]
		ticket = ticket[0]
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

	#def setWatcher tid, nick
	#end

	#def unsetWatcher tid, nick
	#end

end