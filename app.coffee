express = require 'express'
url = require 'url'
crypto = require 'crypto'
app = express()

# Load parsers
parsers = require "./parsers"

# Load custom hosts
hosts = require './hosts'

# Debug enabled?
DEBUG = true

####################################################
# PREPARE DDBB
####################################################

if process.env.VCAP_SERVICES
	env = JSON.parse process.env.VCAP_SERVICES
	mongo = env['mongodb-1.8'][0]['credentials']
else
	mongo =
		"hostname": "localhost"
		"port": 27017
		"username": ""
		"password": ""
		"name": ""
		"db": "db"

generateMongoUrl = (_object) ->
	_object.hostname = (_object.hostname || 'localhost')
	_object.port = (_object.port || 27017)
	_object.db = (_object.db || 'test')
	if _object.username and _object.password
		"mongodb://" + _object.username + ":" + _object.password + "@" + _object.hostname + ":" + _object.port + "/" + _object.db;
	else
		"mongodb://" + _object.hostname + ":" + _object.port + "/" + _object.db;

mongourl = generateMongoUrl mongo

####################################################
# BACK
####################################################

class rss
	# { hash, url, parser }
	# TODO custom name Fex: /the-walking-dead-1080-publihd.xml
	constructor: (@url, @parser="default") ->
		if url
			@getParser()
			@createHash()

	# Get the RSS parser based on hosts.json
	getParser: ->
		host = url.parse(@url).pathname.replace("/", "").replace("www.", "")
		@parser = hosts[host] if hosts[host]?

	# Get the RSS object from ID
	getFromId: (_id) ->
		# MongoDB

	# Create a MD5 unique hash for the URL provided
	# MD5 ( RSS_URL + PARSER NAME )
	createHash: ->
		if @url and @parser
			hash = crypto.createHash 'md5'
			@hash = hash.update(@url + @parser).digest('hex')

	# Save the object
	save: ->
		# MongoDB handler

# Load the parser
loadParser = (_parser) ->
	if parsers[_parser]
		new parsers[parserType]()
	else
		null

####################################################
# SITE
####################################################

app.use express.bodyParser()

app.get "/", (request, response) ->
	response.sendfile "html/home.html"

app.post "/", (request, response) ->
	rssUrl = request.param 'rss'
	item = new rss rssUrl
	#item.getParser()
	#item.createHash()
	item.save()
	response.redirect "/#{item.hash}.xml"
	response.end()

# RSS Request
app.get "/:rss.xml", (request, response) ->
	response.send 'load parser here!'
	response.end()

# Start server
app.listen process.env.VCAP_APP_PORT || 3000
