import { diff, h } from "virtual-dom";
import { Button, Text, View } from "./components/Native";
import { createStore } from "redux";

function reducer(state = 0, action) {
	switch (action.type) {
	case "INCREMENT":
		return state + 1;
	default:
		return state;
	}
}

const store = createStore(reducer);
store.subscribe(update);

const increment = () => store.dispatch({ type: "INCREMENT" })
function App(count) {
	return (
		<View>
			<Text>{count}</Text>
			<Button onClick={increment}>Increment</Button>
		</View>
	);
}

var tree;
function render() {
	const count = store.getState();

	var newTree = App(count);
	var patches;
	if (!tree) {
		patches = null;
	} else {
		try {
			patches = diff(tree, newTree);
		} catch (e) {
			console.log(e.message);
			console.log(e);
		}
	}
	tree = newTree;

	return { tree, patches };
}

window.render = render;
