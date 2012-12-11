http = require 'http'
elementtree = require 'elementtree'

class parser
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
		@get _url, =>
			@parse _callback

	parse: (_callback) ->
		_callback.call @, @tree

	foo: ->
		console.log "DIS IS DEFAULT"

class nyaaeu extends parser

	foo: ->
		console.log "DIS IS NYAAEU"

module.exports = 
	'default': parser
	'nyaaeu': nyaaeu
