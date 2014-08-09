INTERVAL_RETRY = 1000
JSONP_FUNC = 'AxeEngine.jsonCallback'

RegExp.escape = (str) ->
    str.replace /[-\/\\^$*+?.()|[\]{}]/g, '\\$&'

JSONP_REGEXP = new RegExp "^#{RegExp.escape JSONP_FUNC}\\(([\\s\\S]*)\\)"

clone = (obj) ->
	return obj if obj is null or typeof(obj) isnt 'object'
	t = obj.constructor()
	t[key] = clone value for key, value of obj
	return t

loadAxeEngine = (config) ->

	AxeEngine =
		http: {}
		resolverManager: resolverManager

	if config.httpGet
		AxeEngine.http.httpGet = config.httpGet

		if not config.json

			AxeEngine.http.json = (url, encoding) ->
				return new Promise (resolve, reject) ->
					AxeEngine.http.httpGet url, encoding
					.then (data) ->
						resolve JSON.parse(data)
					.then null, reject

		if not config.jsonp

			AxeEngine.http.jsonp = (url, encoding) ->
				return new Promise (resolve, reject) ->
					AxeEngine.http.httpGet url, encoding
					.then (data) ->
						regexp = new RegExp JSONP_REGEXP
						match = data.match regexp
						if match?
							resolve JSON.parse(match[1])
						else
							throw new Error "Invalid JSON: #{url}"
					.then null, reject

	if config.json

		AxeEngine.http.json = config.json

	if config.jsonp

		AxeEngine.http._jsonp = config.jsonp
		AxeEngine.http._jsonpStatus = 0
		if config.jsonCallback
			AxeEngine.jsonCallback = config.jsonCallback
		AxeEngine.http.jsonp = () ->
			args = arguments
			return new Promise (resolve, reject) ->
				if AxeEngine.http._jsonpStatus is 0
					AxeEngine._jsonpStatus = -1
					AxeEngine.http._jsonp.apply null, args
					.then () -> 
						AxeEngine._jsonpStatus = 0
						resolve arguments
					.then null, () -> 
						AxeEngine._jsonpStatus = 0
						reject arguments
				else
					setTimeout () ->
						AxeEngine.http.jsonp.apply null, args
						.then resolve, reject
					, INTERVAL_RETRY


	return AxeEngine


resolverManager =

	resolvers: {}

	register: (name, resolver) ->
		if resolverManager.resolvers[name]
			throw new Error "Resolver \"#{name}\" already registered."
		else
			resolverManager.resolvers[name] = resolver

	create: (name, vid) ->
		resolverClass = resolverManager.resolvers[name]
		if resolverClass?
			return new resolverClass vid
		else
			throw new Error "Resolver \"#{name}\" not found."


class resolver

	constructor: () ->
		@__constructor.apply @, arguments

	__constructor: (@vid) ->
		@versionInfo =
			status: 0

		@qualityInfo =
			status: 0

		@configInfo =
			status: 0

	getConfig: () ->
		return new Promise ((resolve, reject) ->
			if @configInfo.status is 0
				@configInfo.status = -1
				@_getConfig()
				.then (() ->
					@configInfo.status = 1
					resolve @configInfo.config
				).bind(@)
				, ((err) ->
					@configInfo.status = 0
					reject.apply null, arguments
				).bind(@)
			else if @configInfo.status is 1
				resolve @configInfo.config
			else
				throw new Error 'Duplicate calling getConfig'
		).bind(@)

	listVersion: () ->
		return new Promise ((resolve, reject) ->
			if @versionInfo.status is 0
				@versionInfo.status = -1
				@_listVersion()
				.then (() ->
					@versionInfo.status = 1
					resolve @versionInfo.list
				).bind(@)
				, (() ->
					@versionInfo.status = 0
					reject.apply null, arguments
				).bind(@)
			else if @versionInfo.status is 1
				resolve @versionInfo.list
			else
				throw new Error 'Duplicate calling listVersion'
		).bind(@)

	getCurrentVersion: () ->
		if @versionInfo.current?
			return @versionInfo.current
		else
			throw new Error 'Versions not loaded.'

	listQuality: () ->
		return new Promise ((resolve, reject) ->
			if @qualityInfo.status is 0
				@qualityInfo.status = -1
				@_listQuality()
				.then (() ->
					@qualityInfo.status = 1
					resolve @qualityInfo.list
				).bind(@)
				, ((err) ->
					@qualityInfo.status = 0
					reject.apply null, arguments
				).bind(@)
			else if @qualityInfo.status is 1
				resolve @qualityInfo.list
			else
				throw new Error 'Duplicate calling listQuality'
		).bind(@)

	getCurrentQuality: () ->
		if @qualityInfo.current?
			return @qualityInfo.current
		else
			throw new Error 'Qualities not loaded.'

	getUrl: () -> @_getUrl()

	switchVersion: (version) ->
		return new Promise ((resolve, reject) ->
			if version is @versionInfo.current
				resolve()
			else if @versionInfo.status isnt 1
				throw new Error 'Version not available'
			else
				@versionInfo.status = -2
				@backup =
					vid: @vid
					configInfo: clone @configInfo
					versionInfo: clone @versionInfo
					qualityInfo: clone @qualityInfo
				@_switchVersion version
				.then (() ->
					backup = null
					@versionInfo.status = 1
					resolve.apply @, arguments
				).bind(@)
				, (() ->
					@restoreVersion()
					reject.apply @, arguments
				).bind(@)
		).bind(@)

	restoreVersion: () ->
		if @backup?
			@vid = @backup.vid
			@configInfo = @backup.configInfo
			@versionInfo = @backup.versionInfo
			@qualityInfo = @backup.qualityInfo

	_switchVersion: (version) ->
		return new Promise ((resolve, reject) ->
			@versionInfo.current = version
			resolve()
		).bind(@)

	switchQuality: (quality) ->
		return new Promise ((resolve, reject) ->
			if quality is @qualityInfo.current
				resolve()
			else if @qualityInfo.status isnt 1
				throw new Error 'Quality not available'
			else
				@qualityInfo.status = -2
				backup =
					configInfo: clone @configInfo
					versionInfo: clone @versionInfo
					qualityInfo: clone @qualityInfo
				@_switchQuality quality
				.then (() ->
					@qualityInfo.status = 1
					resolve.apply @, arguments
				).bind(@)
				, (() ->
					@vid = backup.vid
					@configInfo = backup.configInfo
					@versionInfo = backup.versionInfo
					@qualityInfo = backup.qualityInfo
					reject.apply @, arguments
				).bind(@)
		).bind(@)

	_switchQuality: (quality) ->
		return new Promise ((resolve, reject) ->
			@qualityInfo.current = quality
			resolve()
		).bind(@)


if window?
	window.loadAxeEngine = () ->
		window.AxeEngine = loadAxeEngine.apply null, arguments
else if module?
	module.exports = () ->
		global.AxeEngine = loadAxeEngine.apply null, arguments
