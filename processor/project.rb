require './crud/project'

# The project proccessor is responsible for handling all requests that use the project CRUD.
class ProjectProcessor
	
	# Constructor
	#
	# +crud+:: The project CRUD
	def initialize crud
		@projects = crud
	end

	# Add a new project.
	# 
	# +machinename+:: The machinename of the project
	# +title+:: The projects title
	# +description+:: The projects description
	# +maintainers+:: The projects maintainers
	# +watchers+:: The projects watchers
	#
	# Returns the projects id or nil in case of error.
	def add machinename, title, description, maintainers, watchers
		@projects.create Hash[
			'machinename' => machinename,
			'title' => title,
			'description' => description,
			'maintainers' => maintainers,
			'watchers' => watchers]
	end

	# Delete a project by machinename.
	#
	# +machinename+:: The machinename to delete
	#
	# Returns true if the project was deleted, false if there was no such project and nil in case of error.
	def delete machinename
		@projects.delete ['machinename', machinename]
	end

	# Check if a project exists by machinename.
	#
	# +machinename+:: The machinename to check for
	#
	# Returns true if the project exists, false otherwise.
	def exists? machinename
		project = @projects.read ['id'], ['machinename', machinename]
		project.count > 0 ? true : false
	end

	# Get the machinename from a project by its id.
	#
	# +id+:: The projects id
	#
	# Returns the projects machinename or nil in case there is no such project.
	def getMachinename id
		project = @projects.read ['machinename'], ['id', id]
		if project.count > 0
			project[0]['machinename']
		else
			nil
		end
	end

	# Gete a projects id by its machinename.
	#
	# +machinename+:: The machinename to look the id up for
	#
	# Returns the projects id or nil in case there is no such project.
	def getId machinename
		project = @projects.read ['id'], ['machinename', machinename]
		if project.count > 0
			project[0]['id']
		else
			nil
		end
	end

	# Get a lis of all projects.
	#
	# Returns an array with all projects and their machinename, title and description.
	def getNiceList
		@projects.read ['machinename', 'title', 'description']
	end

end