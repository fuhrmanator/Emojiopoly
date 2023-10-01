const HtmlWebpackPlugin = require('html-webpack-plugin');
const path = require('path');

module.exports = {
    plugins: [
        new HtmlWebpackPlugin({
            filename: '/dist/public/board.html',
            template: './src/public/index.html',
        })
    ],
    entry: './src/public/main.ts',
    output: {
        filename: 'bundle.js',
        path: path.resolve(__dirname, 'dist', 'public'),
    },
    devServer: {
        static: path.join(__dirname, 'dist'),
        historyApiFallback: true,
        port: 8080,
    },
    module: {
        rules: [
            {
                test: /\.tsx?$/,
                use: 'ts-loader',
                exclude: /node_modules/,
            },
        ],
    },
    resolve: {
        extensions: ['.tsx', '.ts', '.js'],
    },






    // output: {
    //     filename: 'dist/public/bundle.js'
    // },
    // module: {
    //     rules: [
    //         { test: /\.tsx?$/, loader: 'ts-loader' }
    //     ]
    // }
}