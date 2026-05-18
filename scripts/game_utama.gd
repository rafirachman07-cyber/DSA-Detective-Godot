extends Control

# --- SAMBUNGAN UI ---
@onready var info_tinggi = $MainLayout/WorkArea/PanelContainer/VBoxContainer/InfoTinggi
@onready var info_rambut = $MainLayout/WorkArea/PanelContainer/VBoxContainer/InfoRambut

@onready var label_status = $MainLayout/WorkArea/PanelContainer2/VBoxContainer/Label
@onready var btn_aksi = $MainLayout/WorkArea/PanelContainer2/VBoxContainer/Button
@onready var input_pencarian = $MainLayout/WorkArea/PanelContainer2/VBoxContainer/InputPencarian

@onready var daftar_temuan = $MainLayout/WorkArea/PanelContainer3/ScrollContainer/VBoxContainer

# --- DATA STORAGE KITA ---
var stack_queue_data = [] 
var hash_map_tersangka = {} 
var graph_koneksi = {} # <--- INI UNTUK GRAPH (Adjacency List)
var mode_dsa = "stack"

func _ready():
	if GameManager.suspects_data.size() > 0:
		stack_queue_data = GameManager.suspects_data.duplicate()
		
		# MEMBANGUN HASH MAP & GRAPH SECARA BERSAMAAN
		for i in range(GameManager.suspects_data.size()):
			var tersangka = GameManager.suspects_data[i]
			var nama = tersangka["nama"]
			
			# 1. Masukkan ke Hash Map (Untuk pencarian cepat)
			hash_map_tersangka[nama] = tersangka
			
			# 2. Bangun Graph (Adjacency List) - Simulasi Komplotan
			var komplotan = []
			# Hubungkan dengan tersangka sebelum dan sesudahnya (Benang merah)
			if i > 0:
				komplotan.append(GameManager.suspects_data[i-1]["nama"])
			if i < GameManager.suspects_data.size() - 1:
				komplotan.append(GameManager.suspects_data[i+1]["nama"])
			
			# Simpan daftarnya ke dalam Graph
			graph_koneksi[nama] = komplotan
			
	update_ui_mode()

# --- LOGIKA TAMPILAN TOMBOL TENGAH ---
func update_ui_mode():
	if mode_dsa == "stack":
		btn_aksi.text = "pop() - Ambil Terakhir"
		label_status.text = "Mode: STACK (LIFO)"
		input_pencarian.hide()
	elif mode_dsa == "queue":
		btn_aksi.text = "dequeue() - Ambil Pertama"
		label_status.text = "Mode: QUEUE (FIFO)"
		input_pencarian.hide()
	elif mode_dsa == "hashmap":
		btn_aksi.text = "get(Key) - Cari Tersangka"
		label_status.text = "Mode: HASH MAP (Pencarian Instan)"
		input_pencarian.show()
	elif mode_dsa == "graph":
		btn_aksi.text = "Bongkar Jaringan (Graph)"
		label_status.text = "Mode: GRAPH (Cari Komplotan)"
		input_pencarian.show()

# --- LOGIKA AKSI UTAMA ---
func _on_btn_aksi_pressed():
	var data_tersangka
	
	if mode_dsa == "stack" and stack_queue_data.size() > 0:
		data_tersangka = stack_queue_data.pop_back()
	elif mode_dsa == "queue" and stack_queue_data.size() > 0:
		data_tersangka = stack_queue_data.pop_at(0)
	elif mode_dsa == "hashmap":
		var nama_dicari = input_pencarian.text
		if hash_map_tersangka.has(nama_dicari):
			data_tersangka = hash_map_tersangka[nama_dicari]
		else:
			label_status.text = "404: Tersangka tidak ditemukan!"
			return
			
	elif mode_dsa == "graph":
		# --- LOGIKA KHUSUS GRAPH ---
		var nama_dicari = input_pencarian.text
		if graph_koneksi.has(nama_dicari):
			var jaringan = graph_koneksi[nama_dicari] # Tarik data komplotannya
			
			# Tampilkan visual ke panel kiri
			info_tinggi.text = "Target Utama: " + nama_dicari
			info_rambut.text = "Jumlah Komplotan: " + str(jaringan.size()) + " orang"
			label_status.text = "Menemukan Benang Merah!"
			
			# Tulis judul di panel daftar kanan
			var pemisah = Label.new()
			pemisah.text = "--- JARINGAN: " + nama_dicari.to_upper() + " ---"
			daftar_temuan.add_child(pemisah)
			
			# Keluarkan semua nama komplotannya
			for anggota in jaringan:
				var nama_baru = Label.new()
				nama_baru.text = " 🔗 " + anggota
				daftar_temuan.add_child(nama_baru)
			return # Langsung stop di sini karena visual Graph beda dari yang lain
		else:
			label_status.text = "404: Target tidak memiliki jaringan!"
			return
	else:
		label_status.text = "Berkas habis atau mode belum aktif!"
		return
		
	# Update UI normal untuk Stack, Queue, dan Hashmap
	info_tinggi.text = "Tinggi: " + str(data_tersangka["tinggi_cm"]) + " cm"
	info_rambut.text = "Rambut: " + str(data_tersangka["warna_rambut"])
	label_status.text = "Menganalisis: " + data_tersangka["nama"]
	
	var nama_list = Label.new()
	nama_list.text = "- " + data_tersangka["nama"]
	daftar_temuan.add_child(nama_list)

# --- FUNGSI TOMBOL ATAS ---
func _on_btn_stack_pressed():
	mode_dsa = "stack"
	update_ui_mode()

func _on_btn_queue_pressed():
	mode_dsa = "queue"
	update_ui_mode()

func _on_btn_hash_map_pressed():
	mode_dsa = "hashmap"
	update_ui_mode()

func _on_btn_graph_pressed():
	mode_dsa = "graph"
	update_ui_mode()

func _on_btn_reset_pressed():
	stack_queue_data = GameManager.suspects_data.duplicate()
	input_pencarian.text = ""
	label_status.text = "Sistem Reset. Berkas utuh."
	for anak in daftar_temuan.get_children():
		anak.queue_free()


func _on_btn_back_pressed():
	get_tree().change_scene_to_file("res://scripts/main_menu.tscn")
