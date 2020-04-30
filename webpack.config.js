const path = require('path')

module.exports = {
	mode: process.env.NODE_ENV || 'development',
	entry: ['@babel/polyfill', path.resolve(__dirname, 'src', 'main.js')],
	output: {
		path: path.resolve(__dirname, 'dist'),
		filename: 'main.js'
	},
	module: {
		rules: [
			{
				test: /\.js$/,
				exclude: /node_modules/,
				use: {
					loader: 'babel-loader',
					options: {
						presets: ['@babel/preset-env']
					}
				}
			}
		]
	},
	resolve: {
		alias: {
			'~': path.resolve(__dirname, 'src')
		}
	},
	node: {
		fs: 'empty'
	},
	devServer: {
		port: process.env.PORT || 8080, // it's possible to specific which port you'd prefer to use
		writeToDisk: true,
		contentBase: path.resolve(__dirname),
		hot: true
	}
}
