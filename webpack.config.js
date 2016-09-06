// var ClosureCompilerPlugin = require('webpack-closure-compiler');

module.exports = {
	entry: "./src/index.js",
	output: {
		filename: "./dist/bundle.js"
	},
	module: {
		loaders: [{
			test: /\.js$/, loader: "babel"
		}]
	},
	// plugins: [
	// 	new ClosureCompilerPlugin({
	// 		compiler: {
	// 			language_in: "ECMASCRIPT6",
	// 			language_out: "ECMASCRIPT5",
	// 			compilation_level: "ADVANCED"
	// 		},
	// 		concurrency: 4
	// 	})
	// ]
};
