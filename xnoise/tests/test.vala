using Pl;

bool test_reader_creation() {
	
	File f = File.new_for_path("./playlist-examples/live-streaming.m3u");
	var reader = new Pl.Reader(f.get_uri());
	return reader != null;
}

bool test_m3u_reading() {
	File f = File.new_for_path("./playlist-examples/live-streaming.m3u");
	var reader = new Pl.Reader(f.get_uri());
	try {
		reader.read();
	}
	catch(Error e) {
		print("test error reading\n");
		return false;
	}
	var uris = reader.get_uris();
	return uris[0] == "http://media.example.com/entire.ts";
}

void main() {

	// CREATE READER
	print("\ntest reader creation:");
	if(test_reader_creation())
		print("\t\tpass\n");
	else
		print("\t\tfail\n");

	// READ M3U
	print("\test m3u reading:");
	if(test_m3u_reading())
		print("\t\tpass\n");
	else
		print("\t\tfail\n");
}

