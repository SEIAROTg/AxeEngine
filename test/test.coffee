path = require 'path'
http = require 'http'
loadAxeEngine = require path.resolve('AxeEngine', __dirname)


httpGet = (url, encoding='utf-8') ->

	return new Promise (resolve, reject) ->

		http.get url, (res) ->

			responseText = ''

			res

			.setEncoding encoding

			.on 'data', (chunk) -> responseText += chunk

			.on 'end', () -> resolve responseText

		.on 'error', reject


AxeEngine = loadAxeEngine
	httpGet: httpGet


test = (site, vid) ->
	return new Promise (resolve, reject) ->
		console.log "========================================"
		console.log "TESTCASE #{vid} @ #{site}"
		console.log "========================================"
		resolver = AxeEngine.resolverManager.create(site, vid)
		resolver.listVersion()
		.then (list) ->
			console.log "versions:"
			def = resolver.getCurrentVersion()
			for version, index in list
				console.log "* #{version}#{if index is def then ' (current)' else ''}"
			return resolver.listQuality()
		.then (list) ->
			console.log "qualities:"
			def = resolver.getCurrentQuality()
			for quality, index in list
				console.log "* #{quality}#{if index is def then ' (current)' else ''}"
			return resolver.getUrl()
		.then (list) ->
			console.log "URLs:"
			for url in list
				console.log url
			resolve()
		.then null, reject


test 'youku', 'XMjg5MTY1Njk2'
.then () -> test 'youku', 'XNzM1MzQyOTA4'
.then null, (err) ->
	console.log err
