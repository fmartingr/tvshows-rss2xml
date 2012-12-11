express = require 'express'
url = require 'url'
crypto = require 'crypto'
mongoose = require 'mongoose'
app = express()

# Load parsers
parsers = require "./parsers"

# Load custom hosts
HOSTS = require './hosts'

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

# Database configuration
DDBB =
	collection: 'rss'
	connection: generateMongoUrl mongo

mongodb = mongoose.createConnection DDBB.connection

mongodb.on 'error', console.error.bind(console, 'connection error: ')
#mongodb.once 'open', ->
#	console.log 'open!'


####################################################
# BACK
####################################################

# The RSS schema for the DDBB
rssSchema = new mongoose.Schema
	hash: { type: String, index: true }
	parser: { type: String, default: 'default' }
	url: String,
	added: { type: Date, default: Date.now }
, collection: 'rss'

# Get the RSS parser based on hosts.json
getParser = (_url) ->
	parser = 'default'
	host = url.parse(_url).host.replace("/", "").replace("www.", "")
	parser = HOSTS[host] if HOSTS[host]?
	parser

# Create a MD5 unique hash for the URL provided
# MD5 ( RSS_URL + PARSER NAME )
createHash = (_url, _parser) ->
	hash = crypto.createHash 'md5'
	hash.update(_url + _parser).digest('hex')

# Make a model from all of this
rss = mongodb.model 'rss', rssSchema

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
	response.sendfile "public/home.html"

app.use("/static", express.static(__dirname + '/public/static'));

app.post "/", (request, response) ->
	rssUrl = request.param 'rss'
	parser = getParser rssUrl
	hash = createHash rssUrl, parser
	rss.findOne { hash: hash }, (_error, _item) ->
		if _item isnt null
			item = _item
		else
			item = new rss 
				url: rssUrl
				hash: hash
				parser: parser
			item.save()
		response.redirect "/#{item.hash}.xml"
		response.end()

# RSS Request
app.get "/:rss.xml", (request, response) ->
	response.send 'load parser here!'
	response.end()

# Start server
app.listen process.env.VCAP_APP_PORT || 3000
