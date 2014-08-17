module.exports = (grunt) ->
	grunt.initConfig
		pkg: grunt.file.readJSON 'package.json'
		watch:
			options:
				spawn: false
			main:
				files: [
					"src/loader.coffee"
					"src/resolvers/*.coffee"
				]
				tasks: ["buildMain"]
			test:
				files: ["test/test.coffee"]
				tasks: ["buildTest"]
		coffee:
			loader:
				options:
					bare: true
				files:
					"dest/loader.js": "src/loader.coffee"
			resolvers:
				files:
					"dest/resolvers.js": "src/resolvers/*.coffee"
			test:
				files:
					"dest/test.js": "test/test.coffee"
		copy:
			package:
				files: [{ src: 'package.json.dest', dest: 'dest/package.json' }]
		concat:
			main:
				options:
					banner: '(function(){'
					footer: '})();'
				src: [
					"dest/loader.js"
					"dest/resolvers.js"
				]
				dest: "dest/AxeEngine.js"
		clean:
			temp:
				src: [
					'dest/loader.js'
					'dest/resolvers.js'
				]
			dest:
				src: ['dest']
		uglify:
			main:
				files: { "dest/AxeEngine.js": "dest/AxeEngine.js" }
	
	grunt.loadNpmTasks 'grunt-contrib-watch'
	grunt.loadNpmTasks 'grunt-contrib-coffee'
	grunt.loadNpmTasks 'grunt-contrib-copy'
	grunt.loadNpmTasks 'grunt-contrib-concat'
	grunt.loadNpmTasks 'grunt-contrib-uglify'
	grunt.loadNpmTasks 'grunt-contrib-clean'
	
	grunt.registerTask 'buildMain', [
		'coffee:loader'
		'coffee:resolvers'
		'concat:main'
		'clean:temp'
	]

	grunt.registerTask 'buildTest', [
		'coffee:test'
	]

	grunt.registerTask 'build', [
		'clean:dest'
		'buildMain'
		'buildTest'
		'copy:package'
	]

	grunt.registerTask 'default', [
		'build'
		'uglify:main'
	]

	grunt.registerTask 'dev', [
		'build'
		'watch'
	]
