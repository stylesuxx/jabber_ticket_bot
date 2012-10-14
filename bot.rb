#!/usr/bin/ruby -w

require 'mysql2'
require 'optparse'
require 'xmpp4r'
require 'xmpp4r/roster'
require './backend'

# This is the main class. it sets up everything needed to run the Bot.
class Bot
	include Jabber

  # Constructor
  #
  # +user+:: The Jid for the Bot
  # +pass+:: The pass for the jid
  # +database+:: The database connection
	def initialize user, pass, database, debug = false
  	@client = Client.new(JID::new(user))
  	@backend = Backend.new(@client, database)
  	Jabber::debug = debug 

    begin
      @client.connect
      @client.auth(pass)
      @client.send(Presence.new.set_type(:available))

      @roster = Roster::Helper.new(@client)
 
      start_subscription_callback
      start_message_callback
      
    rescue Exception => e
      puts "Jabber Error: #{e}"
      exit
    end
	end

	# Process incomming messages and add them to the queue as long as they are not empty
  def start_message_callback
    @client.add_message_callback do |msg|
    	@backend.addStanza msg unless msg.composing? or msg.body.to_s.strip == ""
    end
  end

	# Whenever someone adds the bot to his contact list
  def start_subscription_callback
    @roster.add_subscription_request_callback do |item, pres|
      #we accept everyone
      @roster.accept_subscription(pres.from)
 
      #Now it's our turn to send a subscription request
      x = Presence.new.set_type(:subscribe).set_to(pres.from)
      @client.send(x)
 
      #let's greet our new user
      m=Message::new
      m.to = pres.from
      m.body = "Welcome to the Jabber Ticket  Tracker. If you need help, do not hesitate to ask."
      @client.send(m)
    end
  end

end

begin
  options = {}
  options[:jid] = nil
  options[:jidpass] = nil
  options[:dbhost] = nil
  options[:dbuser] = nil
  options[:dbpass] = nil
  options[:db] = nil 

  usage = "Usage: bot.rb jid pass dbhost dbuser dbpass db [options]"

  OptionParser.new do |opts|
    opts.banner = usage

    opts.separator ""
    opts.separator "Specific options:"

    # Mandatory argument.
    #opts.on("-j", "--jid BOTJID", "The JID to use for the client") do |value|
    #  options[:jid] = value
    #end

    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end.parse!

  if ARGV.length == 6
    options[:jid] = ARGV[0]
    options[:jidpass] = ARGV[1]
    options[:dbhost] = ARGV[2]
    options[:dbuser] = ARGV[3]
    options[:dbpass] = ARGV[4]
    options[:db] = ARGV[5]
  else
    puts usage
    exit    
  end 

  dbh = Mysql2::Client.new(:host => options[:dbhost], :username => options[:dbuser], :password => options[:dbpass], :database => options[:db])
  bot = Bot.new options[:jid], options[:jidpass], dbh

rescue Mysql2::Error => e
  puts "Error code: #{e.errno}"
  puts "Error message: #{e.error}"
  exit
end

Thread.stop