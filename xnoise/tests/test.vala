using Pl;

bool test_reader_creation() {
	var reader = new Pl.Reader();
	return reader != null;
}

bool test_m3u_reading() {
	File f = File.new_for_path("./playlist-examples/test_m3u.m3u");
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("m3u test error reading\n");
		return false;
	}
	var uris = reader.get_uris();
	//print("Size: %s\n", uris.length.to_string());
	return uris[0] == "http://media.example.com/entire.ts";
}

bool test_pls_reading() {
	File f = File.new_for_uri("http://emisora.fundingue.com:8070/listen.pls");
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("pls test error reading\n");
		return false;
	}
	var uris = reader.get_uris();
	//print("Size: %s\n", uris.length.to_string());
	//print("Url0: %s\n",uris[0]);
	return uris[0] == "http://emisora.fundingue.com:8070/";
}

bool test_asx_reading() {
	File f = File.new_for_path("./playlist-examples/asx_test.asx");
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("asx test error reading\n");
		return false;
	}
	var uris = reader.get_uris();
	//print("Size: %s\n", uris.length.to_string());
	return uris[0] == "http://example.com/announcement.wma";
}

bool test_xspf_reading() {
	File f = File.new_for_path("./playlist-examples/xspf.xspf");
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("xspf test error reading\n");
		return false;
	}
	var uris = reader.get_uris();
	//print("Size: %s\n", uris.length.to_string());
	return uris[0] == "http://www.example.com/music/bar.ogg";
}

void main() {
	print("\n");
	// CREATE READER
	print("m3u test reader creation:");
	if(test_reader_creation())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	// READ M3U
	print("test m3u reading:");
	if(test_m3u_reading())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//READ PLS
	print("test pls reading:");
	if(test_pls_reading())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//READ ASX
	print("test asx reading:");
	if(test_asx_reading())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");


	//READ XSPF
	print("test xspf reading:");
	if(test_xspf_reading())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
}

