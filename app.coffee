http = require 'http'
elementtree = require 'elementtree'
express = require 'express'
app = express()

DEBUG = true


####################################################
# BACK
####################################################

###
# Check RSS petition and load its parser
###
checkQuery = (rssUrl) ->
	###
	http.get API_URL, (response) ->
		data = ''
		response.on 'data', (chunk) ->
			data += chunk
		response.on 'end', ->
			tree = elementtree.parse data
			result = ##
	.on 'error', (error) ->
		console.log error.message
	###

####################################################
# SITE
####################################################

# Home request
app.get "/", (request, response) ->
	response.end 'Decent home!'

# RSS Request
app.all "*", (request, response) ->
	if request.url isnt '/'
		response.send request.url.substr(1)
	response.end()

# Start server (AppFog)
app.listen process.env.VCAP_APP_PORT || 3000
