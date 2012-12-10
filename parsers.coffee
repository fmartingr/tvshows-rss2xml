http = require 'http'
elementtree = require 'elementtree'

class parser
	@tree: null

	get: (_url="") ->
		http.get "http://#{_url}", (response) ->
			data = ''
			response.on 'data', (chunk) ->
				data += chunk
			response.on 'end', ->
				@tree = elementtree.parse data
		.on 'error', (error) ->
			console.log error.message

	foo: ->
		console.log "DIS IS DEFAULT"

class nyaaeu extends parser

	foo: ->
		console.log "DIS IS NYAAEU"

module.exports = 
	'default': parser
	'nyaaeu': nyaaeu
