import React, { Component } from 'react';
import { AppRegistry, View, Text, TouchableHighlight } from 'react-native';
import { Style } from '../common';
import FegoRNUpdate from 'fego-rn-update';

export default class World extends Component {
	render() {
		return (
			<View style={[Style.container, { alignItems: 'center', justifyContent: 'center' }]} >
				<Text>第二个rn页面</Text>
				<TouchableHighlight
					underlayColor="transparent"
					onPress={() => {
						FegoRNUpdate.hotReload("World");
					}}>
					<Text>热更新测试</Text>
				</TouchableHighlight>
				<Text>我要更新了</Text>
			</View>
		)
	}
}
AppRegistry.registerComponent('Second', () => World);
