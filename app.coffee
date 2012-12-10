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

# Get the parser needed for the url (if any)
getParserByUrl = (_url) ->
	parserType = 'default'
	host = url.parse(_url).pathname.replace("/", "").replace("www.", "")
	parserType = hosts[host] if hosts[host]?
	parserType

# Load parser based on URL
loadParserByUrl = (_url) ->
	parserType = getParserByUrl
	loadParser parserType

# Load the parser
loadParser = (_parser) ->
	if parsers[_parser]
		new parsers[parserType]()
	else
		null

# Create a MD5 unique hash for the URL provided
# MD5 ( RSS_URL + PARSER NAME )
createHash = (_url, _parserType) ->
	hash = crypto.createHash 'md5'
	hash.update(_url + _parserType).digest('hex')

####################################################
# SITE
####################################################

app.use express.bodyParser()

app.get "/", (request, response) ->
	response.sendfile "html/home.html"

app.post "/", (request, response) ->
	rss = request.param 'rss'
	parserType = getParserByUrl rss
	response.send createHash(rss, parserType)
	response.end()

# RSS Request
app.get "/:rss.xml", (request, response) ->
	response.send 'load parser here!'
	response.end()

# Start server
app.listen process.env.VCAP_APP_PORT || 3000
