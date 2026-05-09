extends Node

const GITHUB_API := "https://api.github.com/repos/qq15725/land/releases/latest"
const GITHUB_RELEASES := "https://github.com/qq15725/land/releases/latest"

# 各平台 release 资产文件名（zip 内的可执行文件名）
const ASSET_ZIP := {
	"Windows": "land-windows.zip",
	"macOS":   "land-macos.zip",
	"Android": "land-android.zip",
}
const EXE_IN_ZIP := {
	"Windows": "land.exe",
}

signal update_available(version: String, changelog: String)
signal download_progress(bytes_downloaded: int, total_bytes: int)
signal download_complete
signal update_error(msg: String)

var _latest_version: String = ""
var _asset_download_url: String = ""
var _check_req: HTTPRequest = null
var _dl_req: HTTPRequest = null


func check() -> void:
	if OS.get_name() == "Web":
		return
	_check_req = HTTPRequest.new()
	add_child(_check_req)
	_check_req.request_completed.connect(_on_check_done)
	var err := _check_req.request(GITHUB_API, ["User-Agent: LandGame/%s" % GameManager.VERSION])
	if err != OK:
		_check_req.queue_free()


func _on_check_done(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_check_req.queue_free()
	_check_req = null
	if code != 200:
		return
	var json := JSON.parse_string(body.get_string_from_utf8())
	if not json is Dictionary:
		return
	var tag: String = json.get("tag_name", "")
	if tag == "" or tag == GameManager.VERSION:
		return
	_latest_version = tag
	var changelog: String = json.get("body", "")
	var platform := OS.get_name()
	var zip_name: String = ASSET_ZIP.get(platform, "")
	for asset in json.get("assets", []):
		if asset.get("name", "") == zip_name:
			_asset_download_url = asset.get("browser_download_url", "")
			break
	update_available.emit(_latest_version, changelog)


func apply_update() -> void:
	var platform := OS.get_name()
	if platform in ["Web", "macOS"] or not platform in ["Windows", "Android"]:
		OS.shell_open(GITHUB_RELEASES)
		return
	if platform == "Android":
		if _asset_download_url != "":
			OS.shell_open(_asset_download_url)
		else:
			OS.shell_open(GITHUB_RELEASES)
		return
	# Windows 自动下载替换
	if _asset_download_url.is_empty():
		OS.shell_open(GITHUB_RELEASES)
		return
	_dl_req = HTTPRequest.new()
	add_child(_dl_req)
	_dl_req.use_threads = true
	_dl_req.request_completed.connect(_on_download_done)
	var zip_path := OS.get_user_data_dir().path_join("land_update.zip")
	_dl_req.download_file = zip_path
	_dl_req.request(_asset_download_url)
	# 用定时器轮询下载进度
	var timer := Timer.new()
	timer.wait_time = 0.3
	timer.timeout.connect(func(): _poll_progress(timer))
	add_child(timer)
	timer.start()


func _poll_progress(timer: Timer) -> void:
	if _dl_req == null:
		timer.queue_free()
		return
	var dl := _dl_req.get_downloaded_bytes()
	var total := _dl_req.get_body_size()
	download_progress.emit(dl, total)


func _on_download_done(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_dl_req.queue_free()
	_dl_req = null
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		update_error.emit("下载失败（错误码 %d）" % code)
		return
	var zip_path := OS.get_user_data_dir().path_join("land_update.zip")
	var exe_name: String = EXE_IN_ZIP.get(OS.get_name(), "")
	if exe_name.is_empty():
		update_error.emit("不支持的平台")
		return
	var exe_data := _extract_file_from_zip(zip_path, exe_name)
	if exe_data.is_empty():
		update_error.emit("解压失败，未找到 %s" % exe_name)
		return
	var new_exe := OS.get_executable_path().get_base_dir().path_join("land_new.exe")
	var f := FileAccess.open(new_exe, FileAccess.WRITE)
	if f == null:
		update_error.emit("写文件失败")
		return
	f.store_buffer(exe_data)
	f = null
	DirAccess.remove_absolute(zip_path)
	_write_and_run_bat(new_exe)


func _extract_file_from_zip(zip_path: String, target_name: String) -> PackedByteArray:
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return PackedByteArray()
	for path in reader.get_files():
		if path.get_file() == target_name:
			var data := reader.read_file(path)
			reader.close()
			return data
	reader.close()
	return PackedByteArray()


func _write_and_run_bat(new_exe: String) -> void:
	var cur_exe := OS.get_executable_path()
	var bat_path := OS.get_user_data_dir().path_join("land_updater.bat")
	var bat := FileAccess.open(bat_path, FileAccess.WRITE)
	bat.store_string("@echo off\r\n")
	bat.store_string("timeout /t 2 /nobreak >nul\r\n")
	bat.store_string("move /y \"%s\" \"%s\"\r\n" % [new_exe, cur_exe])
	bat.store_string("start \"\" \"%s\"\r\n" % cur_exe)
	bat.store_string("del \"%%~f0\"\r\n")
	bat = null
	OS.create_process("cmd.exe", ["/c", bat_path])
	download_complete.emit()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
