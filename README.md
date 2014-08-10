#AxeEngine
a javascript library for resolving the real URL of online videos which works in both [Node.js](http://nodejs.org) and browser.

## Build
	> git clone https://github.com/SEIAROTg/AxeEngine.git
    > cd AxeEngine
    > npm install
    > grunt

Output files will be in `<git dir>/dest/`.

### Test
To run test, simply run `<git dir>/dest/test.js` with Node.js.
 Make sure `test.js` is in the same directory as `AxeEngine.js`.

## Load
AxeEngine works in both Node.js and browser. But actually, there can be various of environments, such as Node.js application, web page, and browser extension. Different environment may have different HTTP interface. Therefore, you need to pass HTTP handler to AxeEngine when loading.

After loading, AxeEngine will be in the global namespace (`global` in Node.js, `window` in browser).

### In Node.js
	var loadAxeEngine = require('axeengine');
    loadAxeEngine({
    	httpGet: < your HTTP handler >
    });

Your HTTP handler should be a function that accepts two arguments `URL` and `encoding` and returns a Promise object which return HTTP Response Body when resolved.

### In Browser
	// loadAxeEngine will be automatically add into window object when including AxeEngine.js
    // Suppose you have no permission to make cross-domain request
    var jsonp = < your jsonp handler >;
    loadAxeEngine({
    	jsonp: < your jsonp handler >,
        jsonpCallback: < your jsonp callback function >
    });

Your jsonp handler should accept the same arguments as HTTP handler and return a Promise object which return parsed JSON Object when resolved.

`jsonpCallback` will used as jsonp callback function, when response arrive, it will be called. You should call `resolve` of Promise in this function.

There will be only one jsonp working at the same time.

If you have permission to make cross-domain request, or do not need cross-domain, you can also pass `httpGet` as in Node.js.

## API

### Create resolver
	var resolver = AxeEngine.resolverManager.create(<resolver name>, <video id>);

* `<resolver name>` is the registration name of resolver. See the list at bottom.
* `<video id>` is the id of the video in its site. It may be in different format in different sites and resolvers.

### Get video title
	resolver.getTitle().then(function(title){
    	// ...
    });

`resolver.getTitle` takes no arguments and return a Promise which returns the title in string when resolved.

### Get versions
A video may have different versions in some sites.

#### List versions
	resolver.listVersion().then(function(list){
    	// ...
    });

`resolver.listVersion` takes no arguments and return a Promise which returns a array of versions.

#### Get current version
	resolver.listVersion().then(function(list){
    	index = resolver.getCurrentVersion();
        version = list[index];
    });

`resolver.getCurrentVersion` returns current version index in version list.

#### Switch version
	resolver.switchVersion(< index >).then(function(){
    	// ...
    });

* `<index>` is the index of the new version in the version list

### Get qualities
A video usually have multiple qualities.

#### List qualities
	resolver.listQuality().then(function(list){
    	// ...
    });

`resolver.listQuality` takes no arguments and return a Promise which returns a array of qualities.

#### Get current version
	resolver.listVersion().then(function(list){
    	index = resolver.getCurrentVersion();
        version = list[index];
    });

`resolver.getCurrentVersion` returns current version index in version list.

#### Switch version
	resolver.switchVersion(< index >).then(function(){
    	// ...
    });

* `<index>` is the index of the new version in the version list


## LICENSE
[GNU Affero General Public License 3.0](http://www.gnu.org/licenses/agpl-3.0.html)

## Supported Site List
| Site            | Resolver name | M3U   | multi-version | multi-quality |
| --------------- |---------------|:-----:|:-------------:|:-------------:|
| v.youku.com     | youku         | Y     | Y             | Y             |
| tv.sohu.com     | sohu          | N     | -             | Y             |
| my.tv.sohu.com  | sohu          | N     | -             | Y             |