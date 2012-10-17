require './processor/user'

# This class handles all incomming messages, and if they are valid commands, handles them.
class IncommingProcessor

	# Constructor
	#
	# +userProcessor+:: User processor
	# +projectProcessor+:: Project processor
	# +ticketProcessor+:: Ticket processor
	def initialize userProcessor , projectProcessor, ticketProcessor #, followupProcessor
		@user = userProcessor
		@project = projectProcessor
		@ticket = ticketProcessor
	end

	# Checks if the message is a valid command and handles it.
	#
	# +command+:: The user command
	# +jid+:: The command invoking users JID
	#
	# Returns a message after handling the command.
	def process command, jid
		# get the jid out of the message
		# get the message text itself
		# look up the user role
		role = 'admin'

		# Switch the commands
		case command

		# add user nick jid@subdomain.domain.tld email@subdomain.domain.tld
		when /^add user ([a-zA-Z0-9]+) ([a-zA-Z0-9]+\@{1}([a-zA-Z0-9]*\.)+([a-zA-Z]+)){1} ([a-zA-Z0-9]+\@{1}([a-zA-Z0-9]*\.)+([a-zA-Z]+)){1}/
			values = command.split

			nick = values[2]
			jid = values[3]
			email = values[4]

			@user.add nick, email, jid

		# Add a new project
		when /^add pro(ject)? ([a-zA-Z0-9]+) \"([a-zA-Z0-9 ]+)\" \"(.*)\"$/
			if role == 'admin'
				values = command.split "\""
				values.delete_if {|i| i==" "}

				machinename = values[0].split " "
				machinename = machinename[2]
				title = values[1]
				description = values[2]

				added = @project.add machinename, title, description, nil, nil
				if added
					msg = "New project '#{machinename}' has been added"
				else
					msg = "There already is a project with this name."
				end
				msg
			end

		# Show all projects
		when /^pro(jects)?$/
			projects = @project.getNiceList

			output = "Projects:"
			projects.each do |row|
				output += "\n#{row['title']} \(#{row['machinename']}\)\n"
				output += "#{row['description']}\n"
				output += "-------------------------------------------"
			end
			output = projects.size > 0 ? output : "There are no projects in the database"
			output

		# Delete a project
		when /^del(ete)? pro(ject)? ([a-zA-Z0-9]+)$/
			if role == 'admin'
				values = command.split " "
				machinename = values[2]

				if @project.getId machinename
					@project.delete machinename
					"Project '#{machinename}' has been deleted."
				else
					"There is no such project."
				end
			end


		# add tracket machinename "Some Title" "some description text"
		when /^add ([a-zA-Z0-9]+) ([a-zA-Z0-9]+) \"([a-zA-Z0-9 ]+)\" \"(.*)\"$/
			values = command.split "\""
			values.delete_if {|i| i == " "}

			params = values[0].split " "

			tracker = params[1]
			machinename = params[2]
			title = values[1]
			description = values[2]

			pid = @project.getId machinename
			if pid
				cid = @user.getId jid

				tid = @ticket.add pid, title, description, cid, tracker
				"New #{tracker} (##{tid}) has been added to #{machinename}."
			else
				"There is no such project."
			end

		# show new tickets
		when /^n(ew)?$/
			tickets = @ticket.getNew

			output = "New unassigned tickets:"
			tickets.each do |ticket|
				tid = ticket['id']
				title = ticket['title']
				tracker = ticket['tracker']
				pid = ticket['pid']

				machinename = @project.getMachinename pid

				output += "\n##{tid} [#{tracker}] <b>\"#{title}\"</b> in #{machinename}"
			end
			output = tickets.count < 1 ? "There are no new tickets." : output
			output

		when /^d(etails)? ([0-9]+)$/
			values = command.split " "
			tid = values[1]

			if @ticket.exists? tid
				ticket = @ticket.getDetails tid

				tid = ticket['id']
				title = ticket['title']
				description = ticket['description']
				tracker = ticket['tracker']
	  		created = ticket['created']
				pid = ticket['pid']
				cid = ticket['creator']
				status = ticket['status']

				machinename = @project.getMachinename pid
				nick = @user.getNickFromId cid

				output = "Details for ticket ##{tid}:"
				output += "\n| ##{tid} [#{tracker}] \"#{title}\" in #{machinename} [#{status}]\n"
				output += "| Added by #{nick} on #{created}\n"
				output += "#{description}"
			else
				output = "There is no such ticket."
			end
			output

		# assign ticket to yourself
		when /^a(ssign )?([0-9]+)$/
			values = command.split " "
			tid = values[1]
			uid = @user.getId jid
			if @ticket.exists? tid
				# AND requesting user is maintainer in this project
				if !@ticket.assigned? tid
					@ticket.assign tid, uid
					"Ticket ##{tid} assigned to yourself."
				else
					nick = @user.getNick uid
					"This ticket is already assigned to #{nick}"
				end
			else
				"There is no such ticket."
			end

		# Delete ticket by id
		when /^del(ete)? ([0-9]+)$/
			values = command.split " "
			tid = values[1]
			deleted = @ticket.delete tid
			if deleted
				msg = "Ticket ##{tid} has been deleted."
			else
				msg = "There is no such ticket."
			end
			msg

		# Close a ticket
		when /^close ([0-9]+)$/
			values = command.split " "
			tid = values[1]

			if @ticket.exists? tid
				closed = @ticket.updateStatus tid, "closed"
				msg = "Ticked ##{tid} has been closed." 
			else
				msg = "There is no such ticket."
			end
			msg

		# update nr status "Followup text"
		when /^update ([0-9]+) ([a-zA-Z0-9]+) \"([a-zA-Z0-9 ]+)\"$/
			puts "updating a ticket"
			# get the ticket id
			# add a followup to the ticket
			# update the status of the ticket

		# Show the requesting users tickets
		when /^m(y)?$/
			uid = @user.getId jid
			tickets = @ticket.getAssigned uid

			output = "Your tickets:"
			tickets.each do |ticket|
				tid = ticket['id']
				title = ticket['title']
				tracker = ticket['tracker']
				status = ticket['status']
				pid = ticket['pid']

				machinename = @project.getMachinename pid

				output += "\n##{tid} [#{tracker}] <b>\"#{title}\"</b> in #{machinename} [#{status}]"
			end
			output = tickets.count < 1 ? "You have no tickets assigned." : output
			output

		# Show the requesting users open bugs
		when /^m(y )?b(ugs)?$/
			puts "Show bugs"

		# Show the requesting users open features
		when /^m(y )?f(eatures)?$/
			puts "Show features"

		# Set the status of a ticket to in_progress
		when /^pro(gress)? ([0-9]+)$/
			values = command.split " "
			tid = values[1]

			if @ticket.exists? tid
				closed = @ticket.updateStatus tid, "in_progress"
				msg = "Ticked ##{tid} is in progress." 
			else
				msg = "There is no such ticket."
			end
			msg

		# Test all methods in the project crud
		when /^testpro$/
			output = "Testing the project methods: "

			#add
			puts "Adding new project"
			id = @project.add 'testauto', 'Automated test', 'This is just an Automated test', nil, nil
			output += "\nNew project added: #{id}"

			#exists?
			puts "Checking if project exists"
			exists = @project.exists? 'testauto'
			output += "\nProject exists: #{exists}"

			#getid
			puts "Getting the projects ID"
			id = @project.getId 'testauto'
			output += "\nThe id is: #{id}"

			#getmachine
			puts "Getting the projects machinename"
			machine = @project.getMachinename id
			output += "\nThe machinename is: #{machine}"

			#list
			puts "Getting the project list"
			puts @project.getNiceList

			#delete
			puts "Deleting the project by machinename"
			deleted = @project.delete machine
			output += "\nProject deleted: #{deleted}"
			output

		# Test all methods in the user crud
		when /^testuser$/
			output = "Testing the user methods:"

			#add
			puts "Adding new user"
			id = @user.add 'autouser', 'autouser@email.at', 'autouser@jid.nla.at'
			output += "\nNew user added: #{id}"

			#exists
			puts "Checking if user exists"
			exists = @user.exists? 'autouser@jid.nla.at'
			output += "\nUser exists: #{exists}"

			#getid
			puts "Getting the users id"
			id = @user.getId 'autouser@jid.nla.at'
			output += "\nThe id is: #{id}"

			#getnick
			puts "Getting the users nick"
			nick = @user.getNick 'autouser@jid.nla.at'
			output += "\nThe nick is: #{nick}"

			#isrole
			puts "Checking if the user is role admin"
			role = @user.isRole? 'autouser@jid.nla.at', 'admin'
			output += "\nThe user is admin: #{role}"

			puts "Checking if the user is role user"
			role = @user.isRole? 'autouser@jid.nla.at', 'user'
			output += "\nThe user is user: #{role}"

			#getrole
			puts "Getting the users role"
			role = @user.getRole 'autouser@jid.nla.at'
			output += "\nThe users role: #{role}"

			#delete
			puts "Deleting the user"
			deleted = @user.delete 'autouser'
			output += "\nUser deleted: #{deleted}"
			output

		# Test all methods in the ticket crud
		when /^testticket$/
			output = "Testing the ticket methods:"

			#add
			puts "Adding new ticket"
			id = @ticket.add 69, "Automated ticket", "this is just an automated ticket", "1", "bug"
			output += "\nNew ticket added: #{id}"

			#check if exists id
			puts "Checking if ticket exists"
			exists = @ticket.exists? id
			output += "\nTicket exists: #{exists}"

			#assign
			puts "Assigning ticket"
			assigned = @ticket.assign id, 1
			output += "\nAssigned ticket #{id}: #{assigned}"

			#change status
			puts "Updating Status"
			updated = @ticket.updateStatus id, "blub"
			output += "\nUpdated status: #{updated}"

			#get status
			puts "Getting Status"
			status = @ticket.getStatus id
			output += "\nStatus: #{status}"

			#check if assigned
			puts "Checking if assigned"
			assigned = @ticket.assigned? id
			output += "\nAssigned: #{assigned}"

			#unassign
			puts "Unassigning ticket"
			unassigned = @ticket.unassign id
			output += "\nUnasigned: #{unassigned}"

			#check if assigned
			puts "Checking if assigned"
			assigned = @ticket.assigned? id
			output += "\nAssigned: #{assigned}"

			#delete
			puts "Deleting ticket"
			deleted = @ticket.delete id
			output += "\nTicket deleted: #{deleted}"		

		when /^sleep$/
			sleep 20
			"Returned from sleeping"

		when /^time$/
			Time.now.localtime.to_s

		when /^ping$/
			"pong"

		when /^help$/
			help

		else
			"Command not recognized: '#{command}'"

		end
	end

	# Returns help text.
	def help
"Help:
<u>User Commands:</u>
ping, help, time
pro(jects) <i>Show a list of projects</i>
new <i>Shows new unasigned tickets</i>
add tracker machinename \"Some Title\" \"some descriptive text\"

<u>Watcher Commands:</u>

<u>Maintainer Commands:</u>
assign nr <i>Assign ticket with nr to yourself</i>
m(y) <i>Show all tickets that are asigned to you and not yet closed</i>
pro(gress) ID <i>Set the status of a ticket to in_progress</i>
m(y )b(ugs) <i>Show assigned open bugs</i>
m(y )f(eatures) <i>Show assigned open features</i>
close ID <i>Close a ticket that is assigned to you</i>

<u>Admin Commands:</u>
add pro(ject) machinename \"Project title\" \"Some descriptive text\"
del(ete) pro(ject) machinename
del(ete) nr Delete ticket with nr

<u>Debugging:</u>
sleep, testpro, testuser, testticket"

	end

end