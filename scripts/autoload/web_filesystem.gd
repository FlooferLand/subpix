extends Node

var js_callbacks := {
	"project_loaded": null
}

func load_file(id: String, accept: String, callback: Callable) -> void:
	# Retrieve the 'gd_callbacks' object from JavaScript
	js_callbacks[id] = JavaScriptBridge.create_callback(func(_js_buff: Array):
		var gd_buff = JavaScriptBridge.get_interface("gd_returns")[id]

		var buffer := PackedByteArray()
		for i in range(gd_buff.byteLength):
			buffer.append(gd_buff[i])
		callback.call(buffer)
	)
	var gd_callbacks: JavaScriptObject = JavaScriptBridge.get_interface("gd_callbacks")
	gd_callbacks.fileLoaded[id] = js_callbacks[id]

	# Calling the thing
	JavaScriptBridge.eval("""loadFile("%s", "%s")""" % [accept, id])

# TODO: Add custom saving back in
func save_file(id: String, buffer: PackedByteArray, filename: String, mime_type: String, inplace: bool = true) -> void:
	JavaScriptBridge.download_buffer(buffer, filename, mime_type)
	#var args: JavaScriptObject = JavaScriptBridge.get_interface("gd_args")["saveFile"]
	#JavaScriptBridge.eval("gd_args['saveFile']['%s'] = {}" % id)
	#args[id]["buffer"] = buffer
	#
	#JavaScriptBridge.eval("saveFile('%s', '%s', '%s', '%s')" % [
	#								id, filename, mime_type, inplace
	#])
