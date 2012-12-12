http = require 'http'
elementtree = require 'elementtree'

class parser
	@url: ''
	@tree: null

	get: (_url, _callback) ->
		console.log "GET: #{_url}" 
		http.get "#{_url}", (response) =>
			data = ''
			response.on 'data', (chunk) =>
				data += chunk
			response.on 'end', =>
				@tree = elementtree.parse data
				_callback.call()
		.on 'error', (error) ->
			console.log error.message

	work: (_url, _callback) ->
		@url = _url
		@get _url, =>
			@parse _callback

	generateItem: (_title, _link, _pubDate, _description) ->
		item =
			item:
				title: _title
				description: _description
				pubDate: _pubDate
				isHD: String((_title.indexOf('720p') != -1) || (_title.indexOf('1080p') != -1))
				link: _link.replace('&', '&amp;')
				torrent: _link.replace('&', '&amp;')
		return item

	parse: (_callback) ->
		items = @tree.findall '*/item'
		feedItems = []
		for item in items
			title = item.find('title').text
			link = item.find('link').text
			pubDate = item.find('pubDate').text
			description = item.find('description').text
			feedItem = @generateItem title, link, pubDate, description
			feedItems.push feedItem
		_callback.call @, feedItems

	foo: ->
		console.log "DIS IS DEFAULT"

class nyaaeu extends parser

	getItemInfo: (_title) ->
		regexp = /[[a-zA-Z0-9\-\_]+\]? (.+) - ([\w\-]+)[\s]?[\.\w]*/i
		# Remove CRC32
		title = _title.replace /\[[A-F0-9]{8}\]/, ''
		# Remove quality
		title = title.replace /\[(1080p|720p)\]/, ''
		matches = title.match regexp
		itemInfo = 
			title: matches[1]
			episode: matches[2]

	generateItem: (_title, _link, _pubDate, _description) ->
		itemInfo = @getItemInfo _title
		item =
			item:
				title: itemInfo.title #+ ' S01E' + itemInfo.episode
				category: 'nyaatorrents'
				description: 'eztv'
				pubDate: _pubDate
				episodeNumber: itemInfo.episode
				isHD: String((_title.indexOf('720p') != -1) || (_title.indexOf('1080p') != -1))
				link: _link.replace('&', '&amp;')
				torrent: _link.replace('&', '&amp;')
		return item

	foo: ->
		console.log "DIS IS NYAAEU"

module.exports = 
	'default': parser
	'nyaaeu': nyaaeu
