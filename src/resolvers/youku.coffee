`function na(e){if(!e)return"";var e=e.toString(),t,n,r,i,s,o=[-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-1,-1,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,-1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1];i=e.length;r=0;for(s="";r<i;){do t=o[e.charCodeAt(r++)&255];while(r<i&&-1==t);if(-1==t)break;do n=o[e.charCodeAt(r++)&255];while(r<i&&-1==n);if(-1==n)break;s+=String.fromCharCode(t<<2|(n&48)>>4);do{t=e.charCodeAt(r++)&255;if(61==t)return s;t=o[t]}while(r<i&&-1==t);if(-1==t)break;s+=String.fromCharCode((n&15)<<4|(t&60)>>2);do{n=e.charCodeAt(r++)&255;if(61==n)return s;n=o[n]}while(r<i&&-1==n);if(-1==n)break;s+=String.fromCharCode((t&3)<<6|n)}return s}function D(e){if(!e)return"";var e=e.toString(),t,n,r,i,s,o;r=e.length;n=0;for(t="";n<r;){i=e.charCodeAt(n++)&255;if(n==r){t+="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt(i>>2);t+="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt((i&3)<<4);t+="==";break}s=e.charCodeAt(n++);if(n==r){t+="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt(i>>2);t+="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt((i&3)<<4|(s&240)>>4);t+="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt((s&15)<<2);t+="=";break}o=e.charCodeAt(n++);t+="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt(i>>2);t+="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt((i&3)<<4|(s&240)>>4);t+="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt((s&15)<<2|(o&192)>>6);t+="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt(o&63)}return t}function E(e,t){for(var n=[],r=0,i,s="",o=0;256>o;o++)n[o]=o;for(o=0;256>o;o++)r=(r+n[o]+e.charCodeAt(o%e.length))%256,i=n[o],n[o]=n[r],n[r]=i;for(var u=r=o=0;u<t.length;u++)o=(o+1)%256,r=(r+n[o])%256,i=n[o],n[o]=n[r],n[r]=i,s+=String.fromCharCode(t.charCodeAt(u)^n[(n[o]+n[r])%256]);return s}function F(e,t){for(var n=[],r=0;r<e.length;r++){for(var i=0,i="a"<=e[r]&&"z">=e[r]?e[r].charCodeAt(0)-97:e[r]-0+26,s=0;36>s;s++)if(t[s]==i){i=s;break}n[r]=25<i?i-26:String.fromCharCode(i+97)}return n.join("")}`

FORMAT =
	flv: 'flv'
	mp4: 'mp4'
	hd2: 'flv'
	'3gphd': 'mp4'
	'3gp': 'flv'
	hd3: 'flv'

QUALITY_LEVEL =
	flv: 0
	flvhd: 0
	mp4: 1
	hd2: 2
	'3gphd': 1
	'3gp': 0
	hd3: 3

QUALITY =
	flv: '标清甲'
	flvhd: '标清乙'
	'3gp': '标清丙'
	mp4: '高清甲'
	'3gphd': '高清乙'
	hd2: '超清'
	hd3: '1080P'


class youku extends resolver

	setPassword: (@password) ->

	_getConfig: () ->
		return new Promise ((resolve, reject) ->
			urlConfig = "http://v.youku.com/player/getPlayList/VideoIDS/#{@vid}/Pf/4/ctype/12/ev/1?__callback=#{JSONP_FUNC}&"
			if @password?
				urlConfig += "password=#{@password}&"
			AxeEngine.http.jsonp urlConfig
			.then ((config) ->
				config = config.data[0]

				if config.error?
					throw new Error config.error

				@configInfo.config = config

				# handle multiple audio languages
				audiolang = config.dvd and config.dvd.audiolang
				if audiolang?
					list = []
					data = []
					current = 0
					for lang, index in audiolang
						list.push lang.lang
						data.push lang.vid
						if lang.vid is config.vidEncoded
							current = index
					current = 0
				else
					list = ['default']
					data =
						default: @vid
					current = 0
				
				@versionInfo.list = list
				@versionInfo.data = data
				@versionInfo.current = current
				@versionInfo.status = 1

				# handle qualities
				list = []
				data = []
				current = 0
				types = config.streamtypes
				for type, index in types
					list.push QUALITY[type]
					data.push type

				@qualityInfo.list = list
				@qualityInfo.data = data
				@qualityInfo.current = current
				@qualityInfo.status = 1

				resolve config
			).bind(@)
			.then null, reject
		).bind(@)

	_listVersion: () -> @getConfig()

	_listQuality: () -> @getConfig()

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
				quality = @qualityInfo.data[@qualityInfo.current]
				charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ/\\:._-1234567890'
				cg = ''
				seed = config.seed
				for i in [charset.length..1]
					seed = (211 * seed + 30031) % 65536
					idx = Math.floor(seed * i / 65536)
					cg += charset[idx]
					charset = charset.slice(0, idx) + charset.slice(idx + 1)
				fileids = config.streamfileids[quality].split '*'
				fileids.pop()
				cg_fun = fileids.map((i) -> cg[i]).join ''
				parts = []
				if config.show?
					e = if config.show.show_paid then '&ypremium=1' else '&ymovie=1'
				else
					e = ''
				for seg in config.segs[quality]
					n = parseInt(seg.no).toString(16).toUpperCase()
					if n.length is 1
						n = '0' + n
					f = cg_fun.slice(0, 8) + n + cg_fun.slice(10)
					a = seg.k
					if a in ['', -1]
						a = config.key2 + config.key1
					c = E(F("b4eto0b4", [19,1,4,7,30,14,28,8,24,17,6,35,34,16,9,10,13,22,32,29,31,21,18,3,2,23,25,27,11,20,5,15,12,0,33,26]).toString(), na(config.ep))
					[sid, token] = c.split '_'
					new_ep = encodeURIComponent(D(E(F("boa4poz1", [19,1,4,7,30,14,28,8,24,17,6,35,34,16,9,10,13,22,32,29,31,21,18,3,2,23,25,27,11,20,5,15,12,0,33,26]).toString(), "#{sid}_#{f}_#{token}")))
					parts[seg.no] =
						url: "http://k.youku.com/player/getFlvPath/sid/#{sid}_00/st/#{FORMAT[quality]}/fileid/#{f}?K=#{a}&hd=#{QUALITY_LEVEL[quality]}&myp=0&ts=#{seg.seconds}&ypp=0#{e}&ep=#{new_ep}&ctype=12&ev=1&token=#{token}&oip=#{config['ip']}"
						size: parseInt seg.size
						length: parseInt seg.seconds
				resolve parts
			).bind(@)
			.then null, reject
		).bind(@)


resolverManager.register 'youku', youku
