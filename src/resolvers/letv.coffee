STRIP_XML = /<playurl><!\[CDATA\[([\s\S]*?)\]\]><\/playurl>/

QUALITY =
	'350': '流畅'
	'1000': '高清'
	'1300': '超清'
	'720p': '720P'
	'1080p': '1080P'

URL_SUFFIX = "&platid=1&splatid=101&tag=gug&gugtype=1&ch=letv&playid=0&termid=1&pay=0&ostype=windows&hwtype=un&format=0&expect=1"

getKey = (t, n) ->
	for i in [1..n]
		t = (t >>> 1) + ((t & 1) << 31 >>> 0)
	return t

getTkey = () ->
	ts = Date.now() / 1000 | 0
	key = 0x2E1C964D
	tkey = getKey(getKey(ts, key % 13) ^ key, key % 17)


class letv extends resolver

	_getConfig: () ->
		return new Promise ((resolve, reject) ->
			urlConfig = "http://api.letv.com/mms/out/video/play?id=#{@vid}&platid=1&splatid=101&format=1&tkey=#{getTkey()}&domain=www.letv.com"
			AxeEngine.http.httpGet urlConfig
			.then ((config) ->
				match = config.match STRIP_XML
				if match is null
					throw new Error 'Failed fetching video information'
				else
					config = JSON.parse match[1]
					@configInfo.config = config
					@configInfo.status = 1
				
				@versionInfo.list = ['default']
				@versionInfo.data = [@vid]
				@versionInfo.current = 0
				@versionInfo.status = 1

				list = []
				data = []
				current = 0
				for key of config.dispatch
					list.push QUALITY[key]
					data.push key
				@qualityInfo.list = list
				@qualityInfo.data = data
				@qualityInfo.current = current
				@qualityInfo.status = 1

				@title = config.title

				resolve()
			).bind(@)
			.then null, reject
		).bind(@)

	_getUrl: () ->
		return new Promise ((resolve, reject) ->
			@getConfig()
			.then ((config) ->
				quality = @qualityInfo.data[@qualityInfo.current]
				url = "#{config.dispatch[quality][0]}#{URL_SUFFIX}".replace 'tss=ios&', ''
				resolve [
					url: url
					size: undefined
					duration: parseInt config.duration
				]
			).bind(@)
			.then null, reject
		).bind(@)

	_getM3U: () ->
		return new Promise ((resolve, reject) ->
			@getConfig()
			.then ((config) ->
				quality = @qualityInfo.data[@qualityInfo.current]
				url = "#{config.dispatch[quality][0]}#{URL_SUFFIX}"
				resolve url
			).bind(@)
			.then null, reject
		).bind(@)


resolverManager.register 'letv', letv
