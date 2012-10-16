require './crud/user'
require './processor/user'
require './crud/project'
require './processor/project'
require './crud/ticket'
require './processor/ticket'
require './processor/incomming'

require 'xmpp4r'
require 'xmpp4r/roster'
require 'xmpp4r/xhtml'

# This is the Bot's backend, it processes incomming messages by adding them to a Queue and then processing them multithreaded
class Backend
  include Jabber

  # Constuctor
  #
  # +jabberConnection+:: A Jabber connection
  # +database+:: The datbase to use
  def initialize jabberConnection, database
    userDB = UserCrud.new database,
                          'users',
                           ['*', 'id', 'nick', 'email', 'jid', 'role', 'registered']
    userActions = UserProcessor.new userDB
    
    projectDB = ProjectCrud.new database,
                                'projects',
                                ['*', 'id', 'machinename', 'title', 'description', 'active', 'created']
    projectActions = ProjectProcessor.new projectDB
    
    ticketDB = TicketCrud.new database, 
                              'tickets', 
                              ['*', 'id', 'title', 'description', 'active', 'created', 'creator', 'tracker', 'status', 'assigned', 'pid']
    ticketActions = TicketProcessor.new ticketDB

    @incomming = IncommingProcessor.new userActions, projectActions, ticketActions


    @client = jabberConnection
    @processing = false
    @stanzaQueue = []
  end

  # Adds a stanza to the process queue.
  #
  # +stanza+:: The stanza to add to the process queue
  def addStanza stanza
    @stanzaQueue.push(stanza)
    if !@processing
      processStanza
    end
  end

  # Processes all incomming stanzas, handles them to the correct processor and returns a message to the user.
  def processStanza
    @processing = true
    while @stanzaQueue.count > 0
      stanza = @stanzaQueue.shift
      Thread.new{
        jid = stanza.from.strip
        command = stanza.body

        response = @incomming.process command, jid

        msg = Message::new stanza.from
        msg.type = :chat
        html = msg.add(XHTML::HTML.new(response.gsub("\n","<br />")))
        msg.body = html.to_text
        @client.send(msg)
      }
    end
    @processing = false
  end

end