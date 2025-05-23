console.log("web_filesystem.js loaded successfully!")

var gd_callbacks = {
	"fileLoaded": {}
};
var gd_returns = {};
var gd_args = {
	"saveFile": {}
};

function loadFile(accept, callback_id) {
	const input = document.createElement("input");
	input.setAttribute("type", "file");
	input.setAttribute("accept", accept);
	input.click();
	input.addEventListener("change", evt => {
		const file = evt.target.files[0];
		const reader = new FileReader();

		reader.readAsArrayBuffer(file);

		reader.onloadend = function(evt) {
			const dataLoaded = gd_callbacks.fileLoaded[callback_id]
			if (dataLoaded) {
				const array = new Uint8Array(reader.result);
				gd_returns[callback_id] = array;
				dataLoaded(array);
			}
		}
	});
}

// TODO: Implement in-place saving (what Photopea does) by caching the file handle
function saveFile(id, filename, mimeType, inplace = true) {
	console.log(gd_args)
	if ((((false))) && window.showSaveFilePicker) {
		const types = []
		types[0] = {
			"description": `Unknown files (${mimeType})`
		}
		types[0]["accept"] = {}
		types[0]["accept"][mimeType] = [ ".txt" ];

		window.showSaveFilePicker({
			suggestedName: (filename || "file"),
			types: types
		}).then(async (fileHandle) => {
			const writableStream = await fileHandle.createWritable();
			await writableStream.write(content);
			await writableStream.close();
		})
	} else {  // Browsers without modern storage (Firefox, IE, etc)
		const buffer = gd_args["saveFile"][id]["buffer"]
		if (buffer == undefined) {
			alert("Web error:\nBuffer is undefined, GDScript failed to send over the buffer")
			return
		}

		const blob = new Blob([buffer], { "type": mimeType });
		const url = URL.createObjectURL(blob);
		
		const link = document.createElement("a");
		link.href = url;
		link.download = filename || "file";
		link.click();

		// Cleanup
		URL.revokeObjectURL(url);
	}
}
