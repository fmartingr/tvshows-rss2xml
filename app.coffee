express = require 'express'
url = require 'url'
crypto = require 'crypto'
mongoose = require 'mongoose'
jstoxml = require 'jstoxml'
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

if process.env.DOTCLOUD_DB_INSTANCES
	DDBB = 
		collection: 'rss'
		connection: process.env.DOTCLOUD_DB_MONGODB_URL
else
	mongo =
		"hostname": "localhost"
		"port": 27017
		"username": ""
		"password": ""
		"name": ""
		"db": "db"

	# Database configuration
	DDBB =
		collection: 'rss'
		connection: generateMongoUrl mongo

generateMongoUrl = (_object) ->
	_object.hostname = (_object.hostname || 'localhost')
	_object.port = (_object.port || 27017)
	_object.db = (_object.db || 'test')
	if _object.username and _object.password
		"mongodb://" + _object.username + ":" + _object.password + "@" + _object.hostname + ":" + _object.port + "/" + _object.db;
	else
		"mongodb://" + _object.hostname + ":" + _object.port + "/" + _object.db;


mongodb = mongoose.createConnection DDBB.connection

mongodb.on 'error', console.error.bind(console, 'connection error: ')
#mongodb.once 'open', ->
#	console.log 'open!'

class feed
	contructor: (@json="", @xml="", @base="") ->

	init: (_title, _link, _original, _pubDate) ->
		@xml = ''
		@json =
			_name: 'rss'
			_attrs:
				version: '2.0'
			_content:
				channel: [
					{ title: _title }
#					{ description: '' }
					{ pubDate: _pubDate }
					{ original: _original }
					{ link: _link }
				]

	addItem: (_item) ->
		@json._content.channel.push _item

	addItems: (_items) ->
		for item in _items
			@addItem item

	getXML: ->
		@xml = jstoxml.toXML @json, { indent: '  '}




####################################################
# BACK
####################################################

# The RSS schema for the DDBB
rssSchema = new mongoose.Schema
	hash: { type: String, index: true }
	parser: { type: String, default: 'default' }
	url: String,
	added: { type: Date, default: Date.now }
	custom_url: String
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
loadParser = (_parser="default") ->
	if parsers[_parser]
		new parsers[_parser]()
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
			response.redirect "/#{_item.hash}.xml"
		else
			item = new rss 
				url: rssUrl
				hash: hash
				parser: parser
			item.save ->
				response.redirect "/#{item.hash}.xml"

# RSS Request
app.get "/:hash.xml", (request, response) ->
	hash = request.params.hash
	item = rss.findOne { $or: [ { custom_url: hash }, { hash: hash } ] }, (_error, _item) ->
		if _item is null
			# List not found
			response.set 'Content-Type', 'text/html'
			response.status 404
			response.sendfile 'public/404.html'
		else
			itemParser = loadParser _item.parser
			#itemParser.foo()
			itemParser.work _item.url, (items) ->
				responseFeed = new feed()
				responseFeed.init 'Title', "http://localhost:3000/#{hash}.xml", 'Original', 'PubDate'
				responseFeed.addItems items
				response.set 'Content-Type', 'application/rss+xml'
				response.send responseFeed.getXML()

# Start server
app.listen process.env.VCAP_APP_PORT || 8080
