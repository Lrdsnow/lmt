extends Control

@onready var packages = lmt.get_package_list()
@onready var app_button = preload("res://src/app_button.tscn")

var focusedButton: Button = null

var show_incompatible = false

var swap = false

var arch = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	var output = []
	OS.execute("uname", ["-p"], output, true)
	arch = output[0].replace("\n", "")
	games()

# UI Input handling
func _input(event):
	if event.is_action_pressed("ui_accept"):
		focusedButton.pressed.emit()

func tools():
	clear()
	swap=true
	$title.text="Element (Tools)"
	for app in lmt.get_array_from_reposJson("tools"):
		var data = lmt.get_package_info(app)
		var compatible = true if arch in data["arch"] or "all" in data["arch"] else false
		if compatible or show_incompatible:
			var i = app_button.instantiate()
			i.name = app
			i.text = app
			i.pressed.connect(app_pressed.bind(app))
			i.get_node("CheckBox").button_pressed = lmt.get_package_install_status(app)
			%apps.add_child(i)
	call_deferred("focus")

func focus():
	focusedButton=%apps.get_children()[1]
	focusedButton.grab_focus()

func games():
	clear()
	swap=false
	$title.text="Element (Games)"
	for app in lmt.get_array_from_reposJson("games"):
		var data = lmt.get_package_info(app)
		var compatible = true if arch in data["arch"] or "all" in data["arch"] else false
		if compatible or show_incompatible:
			var i = app_button.instantiate()
			i.name = app
			i.text = app
			i.pressed.connect(app_pressed.bind(app))
			i.focus_entered.connect(app_pressed.bind(app, i))
			i.get_node("CheckBox").button_pressed = lmt.get_package_install_status(app)
			%apps.add_child(i)
	call_deferred("focus")

func clear():
	for x in %apps.get_children():
		x.queue_free()

func app_pressed(app, button=null):
	if button != null:
		for x in %apps.get_children():
			x.custom_minimum_size.x = 202
		button.custom_minimum_size.x = button.custom_minimum_size.x*1.5
	var data = lmt.get_package_info(app)
	var compatible = true if arch in data["arch"] or "all" in data["arch"] else false
	var compatible_str = "Compatible" if compatible else "Incompatible"
	$panel/label.text = "Package: "+data["name"]+"\nVersion: "+str(data["version"])+"\nSupported Architectures: "+str(data["arch"]).replace('"', '').replace("[", "").replace("]", "")+" ("+compatible_str+")"
	$panel/install/install.pressed.disconnect(install_pkg)
	$panel/installed_game/launch.pressed.disconnect(launch_game)
	$panel/installed_game/Settings.pressed.disconnect(app_settings)
	$panel/installed_tool/Settings.pressed.disconnect(app_settings)
	if lmt.get_package_install_status(app):
		if app in lmt.get_array_from_reposJson("games"):
			$panel/install.hide()
			$panel/installed_tool.hide()
			$panel/installed_game.show()
			$panel/installed_game/launch.pressed.connect(launch_game.bind(app))
			$panel/installed_game/Settings.pressed.connect(app_settings.bind(app))
		else:
			$panel/installed_game.hide()
			$panel/install.hide()
			$panel/installed_tool.show()
			$panel/installed_tool/Settings.pressed.connect(app_settings.bind(app))
	else:
		$panel/installed_game.hide()
		$panel/installed_tool.hide()
		$panel/install.show()
		if compatible:
			$panel/install/install.pressed.connect(install_pkg.bind(app))
		else:
			$panel/install/install.disabled = true
	$panel.show()

func app_settings(_app):
	pass

func launch_game(game):
	OS.execute(OS.get_environment("HOME")+"/.lmt/bin/"+game, [])

func install_pkg(app):
	lmt.install_packages([app])

func _on_swap_pressed():
	if swap:
		games()
	else:
		tools()
