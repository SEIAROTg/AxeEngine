QUALITY =
	'1': '标清'
	'2': '高清'
	'3': '超清'
	'4': '720P'
	'5': '1080P'
	'95': '原画'
	'96': '极速'

get_key = () -> (Date.now()/1000|0) ^ 0x6659A955

get_enc = (tvId) -> AxeEngine.md5("ts56gh1000" + tvId)

class iqiyi extends resolver

	constructor: () ->
		@__constructor.apply @, arguments

		match = @vid.match /(.*)\|(.*)/
		@tvId = match[1]
		@videoID = match[2]

	_getConfig: () ->
		return new Promise (resolve, reject) =>
			urlConfig = "http://cache.video.qiyi.com/vms?key=fvip&src=p&tvId=#{@tvId}&vid=#{@videoID}&vinfo=1&tm=1000&enc=#{get_enc(@tvId)}"
			console.log(urlConfig);
			AxeEngine.http.json urlConfig
			.then (config) =>
				config = config.data
				@configInfo.config = config
				@configInfo.status = 1
				console.log config.vi.cn
				@title = config.vi.vn

				@versionInfo.list = ['default']
				@versionInfo.data = []
				@versionInfo.current = 0
				@versionInfo.status = 1

				list = []
				data = []
				current = 0
				vs = config.vp.tkl[0].vs
				for v in vs
					list.push QUALITY[v.bid]
					data.push v.fs
				@qualityInfo.list = list
				@qualityInfo.data = data
				@qualityInfo.current = current
				@qualityInfo.status = 1

				resolve()
			.then null, reject

	_getUrl: () ->
		return new Promise (resolve, reject) =>
			parts = []
			@getConfig()
			.then (config) =>
				frags = @qualityInfo.data[@qualityInfo.current]
				for frag in frags
					parts.push
						url: "http://data.video.qiyi.com/#{get_key()}/videos#{frag.l}"
						size: frag.b
						duration: frag.d

				getRealUrl = (part) ->
					return new Promise (resolve, reject) ->
						AxeEngine.http.json part.url
						.then (ret) ->
							resolve ret.l

				return Promise.all parts.map(getRealUrl)
			.then (urls) =>
				for url, index in urls
					parts[index].url = url
				resolve parts
			.then null, reject

	_getM3U: () ->
		return new Promise (resolve, reject) =>
			@getConfig()
			.then (config) =>
				resolve undefined
			.then null, reject


resolverManager.register 'iqiyi', iqiyi
