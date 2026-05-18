extends Node

# Variabel array global untuk menyimpan seluruh data JSON
var suspects_data = []

func _ready():
	# Fungsi ini otomatis berjalan saat game pertama kali dijalankan
	load_suspects()

func load_suspects():
	# Membuka file JSON dari folder data
	var file = FileAccess.open("res://data/suspects.json", FileAccess.READ)
	
	if file:
		var json_string = file.get_as_text()
		file.close() # Tutup file setelah isinya disalin
		
		# Mengubah teks JSON menjadi Array/Dictionary yang dipahami Godot
		var parsed_data = JSON.parse_string(json_string)
		
		if typeof(parsed_data) == TYPE_ARRAY:
			suspects_data = parsed_data
			
			# Menguji apakah data masuk ke memori.
			# Menggunakan indeks pertama yaitu 0 untuk standar komparasi struktur datanya.
			print("MEMORI AKTIF! Total tersangka dimuat: ", suspects_data.size())
			print("Tersangka di indeks 0 adalah: ", suspects_data[0]["nama"])
		else:
			print("ERROR: Format JSON tidak dikenali sebagai Array.")
	else:
		print("ERROR: File suspects.json gagal ditemukan!")
