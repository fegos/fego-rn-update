/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
	Platform,
	StyleSheet,
	Text,
	View,
	Image,
	NativeModules,
	TouchableHighlight
} from 'react-native';
import FegoRNUpdate from 'fego-rn-update'

const instructions = Platform.select({
	ios: 'Press Cmd+R to reload,\n' +
		'Cmd+D or shake for dev menu',
	android: 'Double tap R on your keyboard to reload,\n' +
		'Shake or press menu button for dev menu',
});

export default class App extends Component {
	render() {
		return (
			<View style={styles.container}>
				<Image source={require('./img/app.png')} style={{ width: 50, height: 59 }} />
				<Text style={[styles.welcome, { fontFamily: 'song' }]}>&#xe61f;</Text>
				<Text style={styles.welcome}>Welcome to FegoRNUpdate!</Text>
				<Text style={styles.instructions}>To get started, edit App.js</Text>
				<Text style={styles.instructions}>
					{instructions}
				</Text>
				<TouchableHighlight
					underlayColor="transparent"
					onPress={() => {
						FegoRNUpdate.hotReload("");
					}}>
					<Text style={styles.btnText}>热更新测试</Text>
				</TouchableHighlight>
			</View>
		);
	}
}

const styles = StyleSheet.create({
	container: {
		flex: 1,
		justifyContent: 'center',
		alignItems: 'center',
		backgroundColor: '#F5FCFF',
	},
	welcome: {
		fontSize: 20,
		textAlign: 'center',
		margin: 10,
	},
	instructions: {
		textAlign: 'center',
		color: '#333333',
		marginBottom: 5,
	},
	btnText: {
		color: 'blue',
		fontSize: 16
	}
});
