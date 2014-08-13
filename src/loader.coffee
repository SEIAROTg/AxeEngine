INTERVAL_RETRY = 1000

JSONP_REGEXP = new RegExp "^callback\\(([\\s\\S]*)\\)"

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
					url = url.replace /\[\[callback\]\]/, 'callback'
					AxeEngine.http.httpGet url, encoding
					.then (data) ->
						match = data.match JSONP_REGEXP
						if match?
							resolve JSON.parse(match[1])
						else
							throw new Error "Invalid JSON: #{url}"
					.then null, reject

	if config.json

		AxeEngine.http.json = config.json

	if config.jsonp

		AxeEngine.http._jsonp = config.jsonp

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
		return new Promise (resolve, reject) =>
			if @configInfo.status is 0
				@configInfo.status = -1
				@_getConfig()
				.then () =>
					@configInfo.status = 1
					resolve @configInfo.config
				, (err) =>
					@configInfo.status = 0
					reject.apply null, arguments
			else if @configInfo.status is 1
				resolve @configInfo.config
			else
				throw new Error 'Duplicate calling getConfig'

	listVersion: () ->
		return new Promise (resolve, reject) =>
			if @versionInfo.status is 0
				@versionInfo.status = -1
				@_listVersion()
				.then () =>
					@versionInfo.status = 1
					resolve @versionInfo.list
				, () =>
					@versionInfo.status = 0
					reject.apply null, arguments
			else if @versionInfo.status is 1
				resolve @versionInfo.list
			else
				throw new Error 'Duplicate calling listVersion'

	_listVersion: () -> @getConfig()

	getCurrentVersion: () ->
		if @versionInfo.current?
			return @versionInfo.current
		else
			throw new Error 'Versions not loaded.'

	listQuality: () ->
		return new Promise (resolve, reject) =>
			if @qualityInfo.status is 0
				@qualityInfo.status = -1
				@_listQuality()
				.then () =>
					@qualityInfo.status = 1
					resolve @qualityInfo.list
				, (err) =>
					@qualityInfo.status = 0
					reject.apply null, arguments
			else if @qualityInfo.status is 1
				resolve @qualityInfo.list
			else
				throw new Error 'Duplicate calling listQuality'

	_listQuality: () -> @getConfig()

	getCurrentQuality: () ->
		if @qualityInfo.current?
			return @qualityInfo.current
		else
			throw new Error 'Qualities not loaded.'

	getUrl: () -> @_getUrl()

	getM3U: () -> @_getM3U()

	switchVersion: (version) ->
		return new Promise (resolve, reject) =>
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
				.then () =>
					backup = null
					@versionInfo.status = 1
					resolve.apply @, arguments
				, () =>
					@restoreVersion()
					reject.apply @, arguments

	restoreVersion: () ->
		if @backup?
			@vid = @backup.vid
			@configInfo = @backup.configInfo
			@versionInfo = @backup.versionInfo
			@qualityInfo = @backup.qualityInfo

	_switchVersion: (version) ->
		return new Promise (resolve, reject) =>
			@versionInfo.current = version
			resolve()

	switchQuality: (quality) ->
		return new Promise (resolve, reject) =>
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
				.then () =>
					@qualityInfo.status = 1
					resolve.apply @, arguments
				, () =>
					@vid = backup.vid
					@configInfo = backup.configInfo
					@versionInfo = backup.versionInfo
					@qualityInfo = backup.qualityInfo
					reject.apply @, arguments

	_switchQuality: (quality) ->
		return new Promise (resolve, reject) =>
			@qualityInfo.current = quality
			resolve()

	getTitle: () ->
		return new Promise (resolve, reject) =>
			@getConfig()
			.then () =>
				resolve @title
			, reject

if window?
	window.loadAxeEngine = () ->
		window.AxeEngine = loadAxeEngine.apply null, arguments
else if module?
	module.exports = () ->
		global.AxeEngine = loadAxeEngine.apply null, arguments
