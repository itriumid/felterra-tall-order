class_name DiscordPresence
extends RefCounted
## What he's playing, shown on Discord beside his name, for his friends to see: freeing which
## area, or Endless, and how far along; with a button to get the game. Said straight to the Discord
## app running on this computer, the way it listens for games: over its local socket (a named pipe
## on Windows), with no Discord library. If Discord isn't running, nothing happens and nothing is
## sent anywhere. Shown unless the player turns it off (Settings, Online); the privacy page says
## what it shares.
##
## Everything said to Discord is said on a thread of its own, so a slow answer never holds a frame:
## the game hands it what to show, and it sends the latest.

## The Discord application the game shows as: its name there is "Felterra - Tall Order".
const APPLICATION := "1571357113228329012"
const GET_THE_GAME := "https://itrium.id/tall-order"
## Discord takes a new activity at most five times in twenty seconds: what only counts up (his
## level) is sent no more often than this, in seconds; where he is, at once.
const EVERY := 15.0
## How long an answer is waited for, in seconds, on a socket that can be asked whether one's come.
const ANSWER_WAIT := 3.0

const HANDSHAKE := 0
const FRAME := 1
const CLOSE := 2

var _thread: Thread
var _mutex := Mutex.new()
var _semaphore := Semaphore.new()
var _wanted := {}
var _waiting := false
var _quitting := false
## Where the socket is looked for: for a test, a pretend Discord's.
var _paths: Array[String] = []
var _sent := {}
var _sent_at := -INF


## Starts listening for what to show. Looks for Discord where it keeps its socket, unless told
## where (a test's pretend Discord).
func start(paths: Array[String] = []) -> void:
	_paths = paths if not paths.is_empty() else DiscordPresence.socket_paths()
	_thread = Thread.new()
	_thread.start(_run)


## Shows this activity (see activity()), if it's changed enough to be worth saying: where he is at
## once, the rest every EVERY seconds. An empty one clears it.
func show(activity: Dictionary, now: float) -> void:
	if activity == _sent:
		return
	var moved: bool = activity.get("details", "") != _sent.get("details", "") or activity.is_empty() != _sent.is_empty()
	if not moved and now - _sent_at < EVERY:
		return
	_sent = activity
	_sent_at = now
	_mutex.lock()
	_wanted = activity
	_waiting = true
	_mutex.unlock()
	_semaphore.post()


## Stops: Discord clears what was shown when the game lets go of it.
func stop() -> void:
	if _thread == null:
		return
	_mutex.lock()
	_quitting = true
	_mutex.unlock()
	_semaphore.post()
	_thread.wait_to_finish()
	_thread = null


## An activity as Discord shows it: the line under the game's name, the line under that, since
## when, the pictures (see tools/build_discord_art.gd), how many of a crew there are, and the
## button to get the game.
static func activity(details: String, state: String, since: int, picture: String, picture_says: String, crew := 0) -> Dictionary:
	var shown := {
		"details": details, "timestamps": {"start": since},
		"assets": {"large_image": "logo", "large_text": "Felterra: Tall Order", "small_image": picture, "small_text": picture_says},
		"buttons": [{"label": "Get the game", "url": GET_THE_GAME}],
	}
	if not state.is_empty():
		shown.state = state
	if crew > 1:
		shown.party = {"id": "crew-%d" % since, "size": [crew, 4]}
	return shown


## Where the Discord app keeps its socket on this system: a named pipe on Windows; elsewhere, a
## socket in the runtime or temporary folder (or Flatpak's or Snap's, for a Discord installed
## that way), numbered from 0 for each Discord running.
static func socket_paths() -> Array[String]:
	var paths: Array[String] = []
	if OS.get_name() == "Windows":
		for number in 10:
			paths.append("\\\\?\\pipe\\discord-ipc-%d" % number)
		return paths
	var folders: Array[String] = []
	for variable in ["XDG_RUNTIME_DIR", "TMPDIR", "TMP", "TEMP"]:
		var folder := OS.get_environment(variable)
		if not folder.is_empty() and not folder in folders:
			folders.append(folder)
	if not "/tmp" in folders:
		folders.append("/tmp")
	for folder in folders:
		for inside in ["", "app/com.discordapp.Discord", "snap.discord"]:
			for number in 10:
				paths.append(folder.path_join(inside).path_join("discord-ipc-%d" % number))
	return paths


## A frame as Discord reads them: what kind it is and how long, little-endian, then its JSON.
static func frame(kind: int, message: Dictionary) -> PackedByteArray:
	var body := JSON.stringify(message).to_utf8_buffer()
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_u32(0, kind)
	bytes.encode_u32(4, body.size())
	bytes.append_array(body)
	return bytes


func _run() -> void:
	var line: Line = null
	while true:
		_semaphore.wait()
		_mutex.lock()
		var quitting := _quitting
		var activity: Dictionary = _wanted
		var waiting := _waiting
		_waiting = false
		_mutex.unlock()
		if quitting:
			break
		if not waiting:
			continue
		if line == null:
			line = _open()
			if line == null:
				# Discord isn't running: tried again the next time there's something to show.
				continue
		var sent := line.send(FRAME, {
			"cmd": "SET_ACTIVITY", "nonce": str(Time.get_ticks_usec()),
			"args": {"pid": OS.get_process_id(), "activity": activity if not activity.is_empty() else null},
		})
		if not sent or line.receive().is_empty():
			line.close()
			line = null
	if line != null:
		line.close()


## The first Discord that answers the handshake, or null.
func _open() -> Line:
	for path in _paths:
		var line := Line.new()
		if not line.open(path):
			continue
		if line.send(HANDSHAKE, {"v": 1, "client_id": APPLICATION}) and line.receive().get("evt", "") == "READY":
			return line
		line.close()
	return null


## The line to one Discord: its socket, or on Windows its pipe, opened as a file.
class Line:
	var _socket: StreamPeerUDS
	var _pipe: FileAccess

	func open(path: String) -> bool:
		if OS.get_name() == "Windows":
			_pipe = FileAccess.open(path, FileAccess.READ_WRITE)
			return _pipe != null
		_socket = StreamPeerUDS.new()
		if _socket.connect_to_host(path) != OK:
			_socket = null
			return false
		var waited := 0.0
		while _socket.get_status() == StreamPeerSocket.STATUS_CONNECTING and waited < ANSWER_WAIT:
			_socket.poll()
			OS.delay_msec(5)
			waited += 0.005
		if _socket.get_status() != StreamPeerSocket.STATUS_CONNECTED:
			_socket = null
			return false
		return true

	func send(kind: int, message: Dictionary) -> bool:
		var bytes := DiscordPresence.frame(kind, message)
		if _pipe != null:
			_pipe.store_buffer(bytes)
			_pipe.flush()
			return _pipe.get_error() == OK
		return _socket != null and _socket.put_data(bytes) == OK

	## The answer, or {} if there's none, or it says the line's closed.
	func receive() -> Dictionary:
		var header := _take(8)
		if header.size() < 8:
			return {}
		var kind := header.decode_u32(0)
		var body := _take(header.decode_u32(4))
		if kind == CLOSE:
			return {}
		var answer: Variant = JSON.parse_string(body.get_string_from_utf8())
		return answer if answer is Dictionary else {}

	func _take(count: int) -> PackedByteArray:
		if count <= 0:
			return PackedByteArray()
		if _pipe != null:
			# A pipe's read waits for the bytes: this is the presence's own thread.
			return _pipe.get_buffer(count)
		var waited := 0.0
		while _socket != null and waited < ANSWER_WAIT:
			_socket.poll()
			if _socket.get_status() != StreamPeerSocket.STATUS_CONNECTED:
				return PackedByteArray()
			if _socket.get_available_bytes() >= count:
				var got: Array = _socket.get_data(count)
				return got[1] if got[0] == OK else PackedByteArray()
			OS.delay_msec(10)
			waited += 0.01
		return PackedByteArray()

	func close() -> void:
		if _pipe != null:
			_pipe.close()
			_pipe = null
		if _socket != null:
			_socket.disconnect_from_host()
			_socket = null
