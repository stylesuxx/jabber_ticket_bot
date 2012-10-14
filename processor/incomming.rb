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

		# add project machinename "Project Title" "Some description text"
		when /^add pro(ject)? ([a-zA-Z0-9]+) \"([a-zA-Z0-9 ]+)\" \"(.*)\"/
			values = command.split "\""
			values.delete_if {|i| i==" "}

			machinename = values[0].split " "
			machinename = machinename[2]
			title = values[1]
			description = values[2]

			added = @project.add machinename, title, description, nil, nil
			if added
				msg = "New project has been added"
			else
				msg = "There is already a project with this machinename"
			end
			msg

		# show a pretty project list
		when /^pro(jects)?/
			projects = @project.getNiceList

			output = "Projects:"
			projects.each do |row|
				output += "\n#{row['title']} \(#{row['machinename']}\)\n"
				output += "#{row['description']}\n"
				output += "-------------------------------------------"
			end
			output = output == "Projects:" ? "There are no projects in the database" : output
			output

		# del(ete) pro(ject) machinename
		when /^del(ete)? pro(ject)? ([a-zA-Z0-9]+)/
			values = command.split " "
			machinename = values[2]

			@project.delete machinename

		# add tracket machinename "Some Title" "some description text"
		when /^add ([a-zA-Z0-9]+) ([a-zA-Z0-9]+) \"([a-zA-Z0-9 ]+)\" \"(.*)\"/
			values = command.split "\""
			values.delete_if {|i| i==" "}

			params = values[0].split " "

			tracker = params[1]
			machinename = params[2]
			title = values[1]
			description = values[2]

			begin
				pid = @project.getId machinename
				begin
					cid = @user.getId jid
				rescue
					"You are not registered to the Tracker, please contact an admin."
				end
					puts "we are here"
					tid = @ticket.add pid, title, description, cid, tracker
					"New #{tracker} (##{tid}) has been added to #{machinename}."
			rescue => e
			 "Error: #{e.error}"
			end

		# show new tickets
		when /^show new/
			tickets = @ticket.getNew

			output = "New tickets:"
			tickets.each do |ticket|
				tid = ticket['id']
				title = ticket['title']
				description = ticket['description']
				tracker = ticket['tracker']
				created = ticket['created']
				pid = ticket['pid']
				cid = ticket['creator']
				machinename = @project.getMachinename pid
				nick = @user.getNick cid

				output += "\n| ##{tid} [#{tracker}] \"#{title}\" in #{machinename}\n"
				output += "| Added by #{nick} on #{created}\n"
				output += "#{description}\n"
				output += "=================================="
			end
			output = output == "New tickets:" ? "There are no unasigned tickets." : output
			output

		# assign ticket to yourself
		when /^assign ([0-9]+)/
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
		when /^del(ete)? ([0-9]+)/
			values = command.split " "
			tid = values[1]
			deleted = @ticket.delete tid
			if deleted
				msg = "Ticket ##{tid} has been deleted."
			else
				msg = "There is no such ticket."
			end
			msg

		# update nr status "Followup text"
		when /^update ([0-9]+) ([a-zA-Z0-9]+) \"([a-zA-Z0-9 ]+)\"/
			puts "updating a ticket"
			# get the ticket id
			# add a followup to the ticket
			# update the status of the ticket

		# Get all tickets assigned to the requesting user
		when /^my/
			# get the user id from jid
			uid = @user.getId jid
			# get the tickets assigned to that id which are not closed
			tickets = @ticket.getAssigned uid

			output = "Your tickets:"
			tickets.each do |ticket|
				tid = ticket['id']
				title = ticket['title']
				description = ticket['description']
				tracker = ticket['tracker']
				created = ticket['created']
				status = ticket['status']
				pid = ticket['pid']
				cid = ticket['creator']
				machinename = @project.getMachinename pid
				nick = @user.getNick cid

				output += "\n| ##{tid} [#{tracker}] \"#{title}\" in #{machinename} [#{status}]\n"
				output += "| Added by #{nick} on #{created}\n"
				output += "#{description}\n"
				output += "=================================="
			end
			output = output == "Your Tickets:" ? "You have no tickets assigned." : output
			output

		# Test all methods in the project crud
		when /^testpro/
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
		when /^testuser/
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
		when /^testticket/
		

		when /^sleep/
			sleep 20
			"Returned from sleeping"

		when /^test/
			puts "testing the or filter"
			@ticket.testOrFilter

		when /^time/
			Time.now.localtime
		when /^ping/
			"pong"
		when /^help/
			help
		else
			"Command not recognized: #{command}"
		end
	end

	# Returns help text.
	def help
"Help:
User Commands:
ping, help, time
pro(jects) Show a list of projects
show new Shows new unasigned tickets
add tracker machinename \"Some Title\" \"some descriptive text\"

Watcher Commands:

Maintainer Commands:
assign nr Assign ticket with nr to yourself
my Show all tickets that are asigned to you and not yet closed

Debugging:
sleep

Admin Commands:
add pro(ject) machinename \"Project title\" \"Some descriptive text\"
del(ete) pro(ject) machinename
del(ete) nr Delete ticket with nr"

	end

end