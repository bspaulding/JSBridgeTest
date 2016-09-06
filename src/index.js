import { diff, h } from "virtual-dom";
const View = "View";
const Text = "Text";

function render(count) {
	return (
		<View>
			<Text>{count}</Text>
		</View>
	);
}

var count = -1;

var tree;
function App() {
	count += 1;
	console.log(`[App] count: ${count}`);

	var newTree = render(count);
	var patches;
	if (!tree) {
		patches = null;
	} else {
		console.log("getting diff");
		try {
		patches = diff(tree, newTree);
		} catch (e) {
			console.log(e.message);
			console.log(e);
		}
		console.log("got diff");
		console.log(patches);
	}
	tree = newTree;

	return { tree, patches };
}

function run(fn) {
	console.log("run! callback:");
	console.log(fn);

	setInterval(function() {
		console.log("in interval");
		fn(App());
		count += 1;
	}, 1000);
}

window.run = run;
window.App = App;
