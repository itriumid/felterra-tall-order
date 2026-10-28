class_name Session
extends RefCounted
## How players online reach each other: the one piece that knows what carries the packets. The
## rest of the game talks through Godot's multiplayer, whichever peer this hands it, so another
## way of connecting (room codes, a store's lobbies) replaces this file and nothing else.
##
## For now, Godot's own networking: the host listens on a port, and a guest joins by the host's
## address.

const PORT := 7539
const MOST_GUESTS := 3


## A peer listening for guests, or null if the port can't be had.
static func host() -> MultiplayerPeer:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(PORT, MOST_GUESTS) != OK:
		return null
	return peer


## A peer on its way to the host at an address, or null if it can't even set out.
static func join(address: String) -> MultiplayerPeer:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(address, PORT) != OK:
		return null
	return peer


## A dropped connection noticed within seconds, not the half a minute it takes by default: a
## guest's cat steps out of the fight, or a guest starts finding the host again, that much sooner.
static func notice_drops(multiplayer_peer: MultiplayerPeer, peer: int) -> void:
	if multiplayer_peer is ENetMultiplayerPeer:
		var connection := (multiplayer_peer as ENetMultiplayerPeer).get_peer(peer)
		if connection != null:
			connection.set_timeout(0, 4000, 10000)


## Where guests can find the host: its addresses on the networks it's on, the home network's first.
static func addresses() -> Array[String]:
	var found: Array[String] = []
	for address in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127.") and not address.begins_with("169.254."):
			found.append(address)
	found.sort_custom(func(a: String, b: String) -> bool: return a.begins_with("192.168.") and not b.begins_with("192.168."))
	return found
