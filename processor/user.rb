require './crud/user'

# The user processor is responsible for handling all requests that use the User Crud
class UserProcessor
	
	# Constructor
	#
	# +crud+:: The users CRUD
	def initialize crud
		@users = crud
	end

	# Add a new user with the role user and no password set.
	# 
	# +nick+:: The users nick
	# +email+:: The users email
	# +jid+:: The users jid
	#
	# Returns the users id or nil in case of error.
	def add nick, email, jid
		@users.create Hash[
			'nick' => nick,
			'email' => email,
			'jid' => jid,
			'role' => 'user',
			'password' => 'NOTSET']
	end

	# Delete a user by its nick.
	#
	# +nick+:: The users nick to delete
	#
	# Returnd true if the user was deleted, false if there is no such user and nil in case of error
	def delete nick
		@users.delete ['nick', nick]
	end

	# Checks if a user has a specific role.
	#
	# +jid+:: The users JID
	# +role+:: The role to check for
	#
	# Returns true if the user has the role, false otherwise.
	def isRole? jid, role
		user = @users.read ['role'], ['jid', jid]
		role ==	user[0]['role']
	end

	# Gets a users id by his JID.
	#
	# +jid+:: The JID to lookup the id for
	#
	# Returns the users id or nil in case the user does not exist
	def getId jid
		user = @users.read ["id"], ["jid", jid]
		if user.count > 0
			user[0]['id']
		else
			nil
		end
	end

	# Gets a users nick by his JID.
	#
	# +jid+:: The JID to lookup the nick for
	#
	# Returns the users nick or nil in case the user does not exist
	def getNick jid
		user = @users.read ["nick"], ["jid", jid]
		if user.count > 0
			user[0]['nick']
		else
			nil
		end
	end

	# Gets a users nick by his ID
	#
	# +id+:: The id to look the nick up for
	#
	# Returns the users nick or nil in case th user does not exist
	def getNickFromId id
		user = @users.read ["nick"], ["id", id]
		if user.count > 0
			user[0]['nick']
		else
			nil
		end
	end

	# Gets a users role by his JID.
	#
	# +jid+:: The JID to lookup the role for
	#
	# Returns the users role or nil in case the user does not exist
	def getRole jid
		user = @users.read ['role'], ['jid', jid]
		if user.count > 0
			user[0]['role']
		else
			nil
		end
	end

	# Checks if the user exists.
	#
	# +jid+:: The JID to check for existance
	#
	# Returns true if the user exists, false otherwise.
	def exists? jid
		user = @users.read ['id'], ['jid', jid]
		user.count > 0 ? true : false
	end

	#def active? nick
	#end

	#def setRole nick, role
	#end

	#def setMail nick, email
	#end

	#def setPass nick, passhash
	#end

	#def getallByRole role
	#end

	#def auth? nick, passhash
	#end

end