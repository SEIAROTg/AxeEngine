QUALITY = {
	norVid: '标清'
	highVid: '高清'
	superVid: '超清'
	oriVid: '原画'
}

class sohu extends resolver

	constructor: () ->
		@__constructor.apply @, arguments

		match = @vid.match /(.*)=(.*)/
		@type = match[1]
		@vid = match[2]

	_getConfig: () ->
		return new Promise ((resolve, reject) ->
			switch @type
				when 'normal'
					urlConfig = "http://hot.vrs.sohu.com/vrs_flash.action?vid=#{@vid}"
				when 'old'
					urlConfig = "http://hot.vrs.sohu.com/vrs_vms.action?p=flash&old=#{@vid}" # no duration info
				when 'my'
					urlConfig = "http://my.tv.sohu.com/videinfo.jhtml?m=viewtv&vid=#{@vid}"

			AxeEngine.http.json urlConfig # cross-domain allowed
			.then ((config) ->
				@configInfo.config = config

				@versionInfo.list = ['default']
				@versionInfo.data = []
				@versionInfo.current = 0
				@versionInfo.status = 1

				list = []
				data = []
				current = 0
				for key, value of QUALITY when config.data[key]?
					list.push value
					data.push config.data[key]
					if config.data[key] is config.id
						current = list.length - 1
				@qualityInfo.list = list
				@qualityInfo.data = data
				@qualityInfo.current = current
				@qualityInfo.status = 1

				@title = config.data.tvName

				resolve()

			).bind(@)
			.then null, reject

		).bind(@)

	_switchVersion: (version) ->
		return new Promise ((resolve, reject) ->
			@vid = @versionInfo.data[version]
			@configInfo.status = 0
			@getConfig()
			.then resolve, reject
		).bind(@)

	_getUrl: () ->
		return new Promise ((resolve, reject) ->
			@getConfig()
			.then ((config) ->
				getUrlByPart = (part) ->
					return new Promise (resolve, reject) ->
						urlRealfile = "http://#{config.allot}/?prot=#{config.prot}&file=#{config.data.clipsURL[part]}&new=#{config.data.su[part]}"
						AxeEngine.http.httpGet urlRealfile
						.then (ret) ->
							t = ret.split '|'
							resolve
								url: "#{t[0]}#{config.data.su[part].slice(1)}?key=#{t[3]}"
								size: config.data.clipsBytes[part]
								duration: config.data.clipsDuration[part]
						.then null, reject
				return Promise.all [0..config.data.totalBlocks-1].map(getUrlByPart)
			).bind(@)
			.then resolve, reject
		).bind(@)

	_getM3U: () ->
		return new Promise ((resolve, reject) ->
			resolve undefined
		).bind(@)

resolverManager.register 'sohu', sohu
