using Xnoise.Pl;

bool test_reader_creation() {
	var reader = new Xnoise.Pl.Reader();
	return reader != null;
}

bool test_m3u_type_recognition() {
	File f = File.new_for_path("./playlist-examples/test_m3u.m3u");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("m3u test error reading\n");
		return false;
	}
	//print("Size: %s\n", uris.length.to_string());
	return reader.ptype == ListType.M3U;
}

bool test_pls_type_recognition() {
	File f = File.new_for_path("./playlist-examples/pls_test.pls");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("pls test error reading\n");
		return false;
	}
	return reader.ptype == ListType.PLS;
}

bool test_asx_type_recognition() {
	File f = File.new_for_path("./playlist-examples/asx_test.asx");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("asx test error reading\n");
		return false;
	}
	return reader.ptype == ListType.ASX;
}

bool test_wpl_type_recognition() {
	File f = File.new_for_path("./playlist-examples/wpl_test.wpl");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("wpl test error reading\n");
		return false;
	}
	//print("Size: %s\n", uris.length.to_string());
	return reader.ptype == ListType.WPL;
}

bool test_xspf_type_recognition() {
	File f = File.new_for_path("./playlist-examples/xspf.xspf");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("xspf test error reading\n");
		return false;
	}
	return reader.ptype == ListType.XSPF;
}


bool test_m3u_reading() {
	File f = File.new_for_path("./playlist-examples/test_m3u.m3u");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("m3u test error reading\n");
		return false;
	}
	var uris = reader.get_found_uris();
	//print("Size: %s\n", uris.length.to_string());
	return uris[0] == "http://media.example.com/entire.ts" && reader.get_number_of_entries() == 1;
}

bool test_m3u_reading_2() {
	File f = File.new_for_path("./playlist-examples/test_ext_m3u.m3u");
	File t1 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("m3u test error reading\n");
		return false;
	}
	var uris = reader.get_found_uris();
	//print("Size: %s\n", uris.length.to_string());
	return uris[0] == t1.get_uri() && reader.get_number_of_entries() == 5;
}

bool test_asx_remote_reading() {
	File f = File.new_for_uri("http://streams.br-online.de/bayern2_1.asx");
	File t1 = File.new_for_commandline_arg("mms://gffstream-w3a.wm.llnwd.net/gffstream_w3a");
	var reader = new Xnoise.Pl.Reader();
	try {
//		t = new Timer();
//		t.start();
		reader.read(f.get_uri(), null);
//		print("%f\n", t.elapsed(null));
	}
	catch(Error e) {
		print("asx remote test error reading\n");
		return false;
	}
	var uris = reader.get_found_uris();
	//print("Size: %s\n", uris.length.to_string());
  //print("URI0: %s\n", uris[0]);
  //print("URI1: %s\n", uris[1]);
	return uris[0] == t1.get_uri();// && reader.get_number_of_entries() == 5;
}

bool test_asx_bad_xml_remote_reading() {
	File f = File.new_for_uri("http://www.tropicalisima.fm/wmbaladas48.asx");
	File t1 = File.new_for_commandline_arg("mms://67.159.60.125/baladas");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("asx bad xml remote test error reading\n");
		return false;
	}
	var uris = reader.get_found_uris();
	//print("Size: %s\n", uris.length.to_string());
  //print("URI0: %s\n", uris[0]);
  //print("URI1: %s\n", uris[1]);
	return uris[0] == t1.get_uri();// && reader.get_number_of_entries() == 5;
}

bool test_pls_reading_2() {
	File f = File.new_for_path("./playlist-examples/pls_test.pls");
	File t1 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	File t5 = File.new_for_commandline_arg("http://www.site.com:8000/listen.pls");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("pls test error reading\n");
		return false;
	}
	var uri1 = reader.data_collection[0].get_uri();
	var uri5 = reader.data_collection[4].get_uri();
	//print("\nXX: %s\nXX: %s\n", uri1, uri5);

	return (uri1 == t1.get_uri()) && (uri5 == t5.get_uri()) && (reader.get_number_of_entries() == 5);
}

bool test_asx_reading() {
	File f = File.new_for_path("./playlist-examples/asx_test.asx");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("asx test error reading\n");
		return false;
	}
	var uris = reader.get_found_uris();
	//print("Size: %s\n", uris.length.to_string());
	return uris[0] == "http://example.com/announcement.wma";
}

bool test_wpl_reading() {
	File f = File.new_for_path("./playlist-examples/wpl_test.wpl");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("wpl test error reading\n");
		return false;
	}
	var uris = reader.get_found_uris();
	//print("Size: %s\n", uris.length.to_string());
  //print("URI0: %s\n", uris[0]);
	return uris[0] == "mms://win40nj.audiovideoweb.com/avwebdsnjwinlive4051";
}

bool test_xspf_reading() {
	File f = File.new_for_path("./playlist-examples/xspf.xspf");
	File t1 = File.new_for_commandline_arg("/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("xspf test error reading\n");
		return false;
	}
	var uris = reader.get_found_uris();
	//print("\n++1 %s\n", uris[0]);
	//print("++2 %s\n", uris[1]);
	//print("++3 %s\n", t1.get_uri());
	//print("Size: %s\n", uris.length.to_string());
	return (uris[0] == "http://www.example.com/music/bar.ogg" && uris[1] == t1.get_uri());
}

//bool test_asx_writing_abs_paths() {
//	File f = File.new_for_path("./playlist-examples/tmp_asx.asx");
//	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
//	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
//	string current_title_1 = "BUSCANDO UN FINAL";
//	string current_title_2 = "everclear - SMFTA";
//	var writer = new Xnoise.Pl.Writer(ListType.ASX, true);
//	
//	ItemCollection data_collection = new ItemCollection();
//	
//	var data = new Item();
//	data.add_field(Item.Field.URI, t1.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_1);
//	data_collection.append(data);
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_2);
//	data_collection.append(data);
//	
//	try {
//		writer.write(data_collection, f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("asx test error writing %s\n", e.message);
//		return false;
//	}
//	
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("asx test error readwrite\n");
//		return false;
//	}
//	var uris = reader.get_found_uris();
//	//return uris[0] == t1.get_uri() && reader.get_title_for_uri(ref uris[1]) == current_title_2;
//	return uris[0] == t1.get_uri();
//}

//bool test_m3u_writing_abs_paths() {
//	File f = File.new_for_path("./playlist-examples/tmp_m3u.m3u");
//	File t1 = File.new_for_commandline_arg("./playlist-examples/ILONA-BUSCANDO UN FINAL.ogg");
//	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
//	string current_title_1 = "BUSCANDO UN FINAL";
//	string current_title_2 = "everclear - SMFTA";
//	var writer = new Xnoise.Pl.Writer(ListType.M3U, true);
//	
//	ItemCollection data_collection = new ItemCollection();
//	
//	var data = new Item();
//	data.add_field(Item.Field.URI, t1.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_1); //titles are still ignored
//	data_collection.append(data);
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_2); //titles are still ignored
//	data_collection.append(data);
//	
//	try {
//		writer.write(data_collection, f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("m3u test error writing %s\n", e.message);
//		return false;
//	}
//	
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("m3u test error readwrite\n");
//		return false;
//	}
//	var uris = reader.get_found_uris();
//	return uris[0] == t1.get_uri() && reader.get_title_for_uri(ref uris[1]) == current_title_2;
////return uris[0] == t1.get_uri();
//}

//bool test_pls_writing_abs_paths() {
//	File f = File.new_for_path("./playlist-examples/tmp_pls.pls");
//	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
//	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
//	string current_title_1 = "BUSCANDO UN FINAL";
//	string current_title_2 = "everclear - SMFTA";
//	var writer = new Xnoise.Pl.Writer(ListType.PLS, true);
//	
//	ItemCollection data_collection = new ItemCollection();
//	
//	var data = new Item();
//	data.add_field(Item.Field.URI, t1.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_1); //titles are still ignored
//	data_collection.append(data);
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_2); //titles are still ignored
//	data_collection.append(data);
//	
//	try {
//		writer.write(data_collection, f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("pls test error writing %s\n", e.message);
//		return false;
//	}
//	
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("pls test error readwrite\n");
//		return false;
//	}
//	var uris = reader.get_found_uris();
//	//print("uris[1] get title: %s\n", reader.get_title_for_uri(ref uris[1])); //Title is empty
//	return uris[0] == t1.get_uri() && reader.get_title_for_uri(ref uris[1]) == current_title_2;
//}

//bool test_xspf_writing_abs_paths() {
//	File f = File.new_for_path("./playlist-examples/tmp_xspf.xspf");
//	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
//	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
//	string current_title_1 = "BUSCANDO UN FINAL";
//	string current_title_2 = "everclear - SMFTA";
//	var writer = new Xnoise.Pl.Writer(ListType.XSPF, true);
//	
//	ItemCollection data_collection = new ItemCollection();
//	
//	var data = new Item();
//	data.add_field(Item.Field.URI, t1.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_1); //titles are still ignored
//	data_collection.append(data);
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_2); //titles are still ignored
//	data_collection.append(data);
//	
//	try {
//		writer.write(data_collection, f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("xspf test error writing %s\n", e.message);
//		return false;
//	}
//	
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("xspf test error readwrite\n");
//		return false;
//	}
//	var uris = reader.get_found_uris();
//	//print("uris[1] get title: %s\n", reader.get_title_for_uri(ref uris[1])); //Title is empty
//	return uris[0] == t1.get_uri() && reader.get_title_for_uri(ref uris[1]) == current_title_2;
//}


//bool test_asx_writing_rel_paths() {
//	File f = File.new_for_path("./playlist-examples/tmp_asx.asx");
//	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
//	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
//	string current_title_1 = "BUSCANDO UN FINAL";
//	string current_title_2 = "everclear - SMFTA";
//	var writer = new Xnoise.Pl.Writer(ListType.ASX, true);
//	
//	//print("\nuri1: %s\n", t1.get_uri());
//	//print("uri2: %s\n", t2.get_uri());
//	ItemCollection data_collection = new ItemCollection();
//	
//	var data = new Item();
//	data.add_field(Item.Field.URI, t1.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_1);
//	data.target_type = TargetType.ABS_PATH;
//	data_collection.append(data);
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_2);
//	data.target_type = TargetType.REL_PATH;
//	data_collection.append(data);
//	
//	try {
//		writer.write(data_collection, f.get_uri());
//	}
//	catch(Error e) {
//		print("asx test error writing %s\n", e.message);
//		return false;
//	}
//	
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("asx test error readwrite\n");
//		return false;
//	}
//	var uris = reader.get_found_uris();
//	File tmp0 = File.new_for_uri(uris[0]);
//	File tmp1 = File.new_for_uri(uris[1]);
//	//print("\n#0 %s\n",uris[0]);
//	//print("#x %s\n",uris[1]);
//	//print("#1 %s\n", tmp0.get_path());
//	//print("#2 %s\n", t1.get_path());
//	//print("#3 %s\n", f.get_parent().get_relative_path(tmp1));
//	//print("#4 %s\n", f.get_parent().get_relative_path(t1));
//	return tmp0.get_path() == t1.get_path() && f.get_relative_path(tmp1) == f.get_relative_path(t2);
//}

//bool test_m3u_writing_rel_paths() {
//	File f = File.new_for_path("./playlist-examples/tmp_m3u.m3u");
//	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
//	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
//	string current_title_1 = "BUSCANDO UN FINAL";
//	string current_title_2 = "everclear - SMFTA";
//	var writer = new Xnoise.Pl.Writer(ListType.M3U, true);
//	
//	//print("\nuri1: %s\n", t1.get_uri());
//	//print("uri2: %s\n", t2.get_uri());
//	ItemCollection data_collection = new ItemCollection();
//	
//	var data = new Item();
//	data.add_field(Item.Field.URI, t1.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_1);
//	data.target_type = TargetType.ABS_PATH;
//	data_collection.append(data);
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_2);
//	data.target_type = TargetType.REL_PATH;
//	data_collection.append(data);
//	
//	try {
//		writer.write(data_collection, f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("m3u test error writing %s\n", e.message);
//		return false;
//	}
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("m3u test error readwrite\n");
//		return false;
//	}
//	var uris = reader.get_found_uris();
//	File tmp0 = File.new_for_uri(uris[0]);
//	File tmp1 = File.new_for_uri(uris[1]);
//	//print("#1 %s\n", tmp0.get_path());
//	//print("#2 %s\n", t1.get_path());
//	//print("#3 %s\n", f.get_parent().get_relative_path(tmp1));
//	//print("#4 %s\n", f.get_parent().get_relative_path(t1));
//	return tmp0.get_path() == t1.get_path() && f.get_relative_path(tmp1) == f.get_relative_path(t2);
//}

//bool test_pls_writing_rel_paths() {
//	File f = File.new_for_path("./playlist-examples/tmp_pls.pls");
//	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
//	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
//	string current_title_1 = "BUSCANDO UN FINAL";
//	string current_title_2 = "everclear - SMFTA";
//	var writer = new Xnoise.Pl.Writer(ListType.PLS, true);
//	
//	//print("\nuri1: %s\n", t1.get_uri());
//	//print("uri2: %s\n", t2.get_uri());
//	ItemCollection data_collection = new ItemCollection();
//	
//	var data = new Item();
//	data.add_field(Item.Field.URI, t1.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_1);
//	data.target_type = TargetType.ABS_PATH;
//	data_collection.append(data);
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_2);
//	data.target_type = TargetType.REL_PATH;
//	data_collection.append(data);
//	
//	try {
//		writer.write(data_collection, f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("pls test error writing %s\n", e.message);
//		return false;
//	}
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("pls test error readwrite\n");
//		return false;
//	}
//	var uris = reader.get_found_uris();
//	File tmp0 = File.new_for_uri(uris[0]);
//	File tmp1 = File.new_for_uri(uris[1]);
//	//print("#1 %s\n", tmp0.get_path());
//	//print("#2 %s\n", t1.get_path());
//	//print("#3 %s\n", f.get_parent().get_relative_path(tmp1));
//	//print("#4 %s\n", f.get_parent().get_relative_path(t1));
//	return tmp0.get_path() == t1.get_path() && f.get_relative_path(tmp1) == f.get_relative_path(t2);
//}

//bool test_xspf_writing_rel_paths() {
//	File f = File.new_for_path("./playlist-examples/tmp_xspf.xspf");
//	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
//	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
//	string current_title_1 = "BUSCANDO UN FINAL";
//	string current_title_2 = "everclear - SMFTA";
//	var writer = new Xnoise.Pl.Writer(ListType.XSPF, true);
//	
//	//print("\nuri1: %s\n", t1.get_uri());
//	//print("uri2: %s\n", t2.get_uri());
//	ItemCollection data_collection = new ItemCollection();
//	
//	var data = new Item();
//	data.add_field(Item.Field.URI, t1.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_1);
//	data.target_type = TargetType.ABS_PATH;
//	data_collection.append(data);
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_2);
//	data.target_type = TargetType.REL_PATH;
//	data_collection.append(data);
//	
//	try {
//		writer.write(data_collection, f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("pls test error writing %s\n", e.message);
//		return false;
//	}
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("pls test error readwrite\n");
//		return false;
//	}
//	var uris = reader.get_found_uris();
//	File tmp0 = File.new_for_uri(uris[0]);
//	File tmp1 = File.new_for_uri(uris[1]);
//	//print("\n%s\n", uris[0]);
//	//print("%s\n", uris[1]);
//	//print("#1 %s\n", tmp0.get_path());
//	//print("#2 %s\n", t1.get_path());
//	//print("#3 %s\n", f.get_parent().get_relative_path(tmp1));
//	//print("#4 %s\n", f.get_parent().get_relative_path(t1));
//	return tmp0.get_path() == t1.get_path() && f.get_relative_path(tmp1) == f.get_relative_path(t2);
//}

//bool test_asx_readwrite_targettype() {
//	File f = File.new_for_path("./playlist-examples/tmp_asx.asx");
//	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
//	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
//	string current_title_1 = "BUSCANDO UN FINAL";
//	string current_title_2 = "everclear - SMFTA";
//	var writer = new Xnoise.Pl.Writer(ListType.ASX, true);
//	
//	//print("\nuri1: %s\n", t1.get_uri());
//	//print("uri2: %s\n", t2.get_uri());
//	ItemCollection data_collection = new ItemCollection();
//	
//	var data = new Item();
//	data.add_field(Item.Field.URI, t1.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_1);
//	data.target_type = TargetType.ABS_PATH;
//	data_collection.append(data);
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_2);
//	data.target_type = TargetType.REL_PATH;
//	data_collection.append(data);
//	
//	try {
//		writer.write(data_collection, f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("asx test error writing %s\n", e.message);
//		return false;
//	}
//	
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("asx test error readwrite\n");
//		return false;
//	}
//	TargetType[] tts = {};
//	foreach(Item d in reader.data_collection) {
//		tts += d.target_type;
//	}
//	//print("\n%s\n", tts[0].to_string());
//	//print("%s\n", tts[1].to_string());
//	return tts[0]==TargetType.ABS_PATH && tts[1]==TargetType.REL_PATH;
//}

//bool test_m3u_readwrite_targettype() {
//	File f = File.new_for_path("./playlist-examples/tmp_m3u.m3u");
//	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
//	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
//	string current_title_1 = "BUSCANDO UN FINAL";
//	string current_title_2 = "everclear - SMFTA";
//	var writer = new Xnoise.Pl.Writer(ListType.M3U, true);
//	
//	//print("\nuri1: %s\n", t1.get_uri());
//	//print("uri2: %s\n", t2.get_uri());
//	ItemCollection data_collection = new ItemCollection();
//	
//	var data = new Item();
//	data.add_field(Item.Field.URI, t1.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_1);
//	data.target_type = TargetType.ABS_PATH;
//	data_collection.append(data);
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_2);
//	data.target_type = TargetType.REL_PATH;
//	data_collection.append(data);
//	
//	try {
//		writer.write(data_collection, f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("asx test error writing %s\n", e.message);
//		return false;
//	}
//	
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("asx test error readwrite\n");
//		return false;
//	}
//	TargetType[] tts = {};
//	foreach(Item d in reader.data_collection) {
//		tts += d.target_type;
//	}
//	//print("\n%s\n", tts[0].to_string());
//	//print("%s\n", tts[1].to_string());
//	return tts[0]==TargetType.ABS_PATH && tts[1]==TargetType.REL_PATH;
//}


//bool test_pls_readwrite_targettype() {
//	File f = File.new_for_path("./playlist-examples/tmp_pls.pls");
//	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
//	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
//	string current_title_1 = "BUSCANDO UN FINAL";
//	string current_title_2 = "everclear - SMFTA";
//	var writer = new Xnoise.Pl.Writer(ListType.PLS, true);
//	
//	//print("\nuri1: %s\n", t1.get_uri());
//	//print("uri2: %s\n", t2.get_uri());
//	ItemCollection data_collection = new ItemCollection();
//	
//	var data = new Item();
//	data.add_field(Item.Field.URI, t1.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_1);
//	data.target_type = TargetType.ABS_PATH;
//	data_collection.append(data);
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_2);
//	data.target_type = TargetType.URI;
//	data_collection.append(data);
//	
//	try {
//		writer.write(data_collection, f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("asx test error writing %s\n", e.message);
//		return false;
//	}
//	
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("asx test error readwrite\n");
//		return false;
//	}
//	TargetType[] tts = {};
//	foreach(Item d in reader.data_collection) {
//		tts += d.target_type;
//	}
//	//print("\n%s\n", tts[0].to_string());
//	//print("%s\n", tts[1].to_string());
//	return tts[0]==TargetType.ABS_PATH && tts[1]==TargetType.URI;
//}


//bool test_xspf_readwrite_targettype() {
//	File f = File.new_for_path("./playlist-examples/tmp_xspf.xspf");
//	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
//	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
//	string current_title_1 = "BUSCANDO UN FINAL";
//	string current_title_2 = "everclear - SMFTA";
//	var writer = new Xnoise.Pl.Writer(ListType.XSPF, true);
//	
//	//print("\nuri1: %s\n", t1.get_uri());
//	//print("uri2: %s\n", t2.get_uri());
//	ItemCollection data_collection = new ItemCollection();
//	
//	var data = new Item();
//	data.add_field(Item.Field.URI, t1.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_1);
//	data.target_type = TargetType.ABS_PATH;
//	data_collection.append(data);
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.add_field(Item.Field.TITLE, current_title_2);
//	data.target_type = TargetType.REL_PATH;
//	data_collection.append(data);
//	
//	
//	data = new Item();
//	data.add_field(Item.Field.URI, t2.get_uri());
//	data.target_type = TargetType.URI;
//	data_collection.append(data);

//	try {
//		writer.write(data_collection, f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("xspf test error writing %s\n", e.message);
//		return false;
//	}
//	
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("xspf test error readwrite\n");
//		return false;
//	}
//	TargetType[] tts = {};
//	foreach(Item d in reader.data_collection) {
//		tts += d.target_type;
//	}
//	//print("\n%s\n", tts[0].to_string());
//	//print("%s\n", tts[1].to_string());
//	return tts[0]==TargetType.ABS_PATH && tts[1]==TargetType.REL_PATH && tts[2]==TargetType.URI;
//}

//bool test_conversion_asx_xspf() {
//	File f = File.new_for_path("./playlist-examples/asx_test.asx");
//	File target = File.new_for_path("./playlist-examples/tmp_copy_as_xspf.xspf");
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("asx test error reading\n");
//		return false;
//	}
//	ItemCollection d = reader.data_collection;
//	var writer = new Xnoise.Pl.Writer(ListType.XSPF, true);
//	try {
//		writer.write(d, target.get_uri(), null);
//	}
//	catch(Error e) {
//		print("asx test error writing %s\n", e.message);
//		return false;
//	}
//	return true; //TODO Howto verify that conversion worked? Maybe do a chain over all types and compare both ends
//}

//bool test_conversion_wpl_asx() {
//	File f = File.new_for_path("./playlist-examples/wpl_test.wpl");
//	File target = File.new_for_path("./playlist-examples/tmp_copy_wpl_as_asx.asx");
//	var reader = new Xnoise.Pl.Reader();
//	try {
//		reader.read(f.get_uri(), null);
//	}
//	catch(Error e) {
//		print("wpl test error reading\n");
//		return false;
//	}
//	ItemCollection d = reader.data_collection;
//	var writer = new Xnoise.Pl.Writer(ListType.ASX, true);
//	try {
//		writer.write(d, target.get_uri(), null);
//	}
//	catch(Error e) {
//		print("wpl test error writing %s\n", e.message);
//		return false;
//	}
//	return true; //TODO Howto verify that conversion worked? Maybe do a chain over all types and compare both ends
//}

bool test_m3u_read_with_no_extension_on_file() {
	File f = File.new_for_path("./playlist-examples/test_ext_m3u");
	File t1 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri(), null);
	}
	catch(Error e) {
		print("m3u test error reading\n");
		return false;
	}
	var uris = reader.get_found_uris();
	//print("Size: %s\n", uris.length.to_string());
	return uris[0] == t1.get_uri() && reader.get_number_of_entries() == 5;
}

bool test_xpsf_read_with_no_extension_on_file() {
	File f = File.new_for_path("./playlist-examples/xf");
	var reader = new Xnoise.Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("m3u test error reading\n");
		return false;
	}
	var uris = reader.get_found_uris();
	return uris[0] == "http://www.example.com/music/bar.ogg" && reader.get_number_of_entries() == 2;
}


MainLoop ml;
void test_asx_async_reading() {
	File f = File.new_for_path("./playlist-examples/malformed_asx.asx");//"http://www.tropicalisima.fm/wmbaladas48.asx");//"http://www.tropicalisima.fm/audios/suave128k.pls");
	var asxreader = new Xnoise.Pl.Reader();
	asxreader.finished.connect(asx_async_finished_cb01);
	asxreader.ref(); //prevent destruction
	try {
		asxreader.read_asyn.begin(f.get_uri(), null);
		
	}
	catch(Error e) {
		print("asx remote test error reading\n");
		return;
	}
	return;// uris[0] == t1.get_uri();// && reader.get_number_of_entries() == 5;
}

void asx_async_finished_cb01(Xnoise.Pl.Reader sender, string pluri) {
	File t1 = File.new_for_commandline_arg("mms://67.159.60.125/baladas");
	var uris = sender.get_found_uris();
	if(uris[0] == t1.get_uri() && sender.get_number_of_entries() == 1)
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
	sender.unref();
	ml.quit();
	return;
}

void test_pls_async_reading() {
	File f = File.new_for_commandline_arg("./playlist-examples/pls_test.pls");
	var asxreader = new Xnoise.Pl.Reader();
	asxreader.finished.connect(pls_async_finished_cb01);
	asxreader.ref(); //prevent destruction
	try {
		asxreader.read_asyn.begin(f.get_uri());
		
	}
	catch(Error e) {
		print("asx remote test error reading\n");
		return;
	}
	return;// uris[0] == t1.get_uri();// && reader.get_number_of_entries() == 5;
}

void pls_async_finished_cb01(Xnoise.Pl.Reader sender, string pluri) {
//	File t1 = File.new_for_commandline_arg("mms://67.159.60.125/baladas");
	var uris = sender.get_found_uris();
	if(sender.get_title_for_uri(ref uris[0]) == "Everclear - So Much For The Afterglow")
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
	sender.unref();
	ml.quit();
	return;
}




////---XML Read/Write
bool test_xml_readwrite_01() {
	//read 
	File source = File.new_for_path("./playlist-examples/asx_test_enc.asx");//"./playlist-examples/asx_test.asx");
	File target = File.new_for_path("./playlist-examples/tmp_asx.xml");

	var mr = new Xnoise.SimpleXml.Reader(source);
	mr.read(); // all data is now in mr.root if read was successful
	if(mr.root == null)
		print("xml reading 1 with errors\n");

	Xnoise.SimpleXml.Node sourcenode = mr.root;
	Xnoise.SimpleXml.Node targetnode;
	//the following can be used to display the nodes with children:
//	int dpth = 0;
//	show_node_data(mr.root, ref dpth);
	

//	//write
//	var mw = new Xnoise.SimpleXml.Writer(mr.root, ""); 
//	//noheader used
//	mw.write(target.get_uri());

//	var res_mr = new Xnoise.SimpleXml.Reader(target);
//	res_mr.read(); // all data is now in mr.root if read was successful
//	if(res_mr.root == null)
//		print("xml reading 2 with errors\n");
//	targetnode = res_mr.root; //store node
//	
//	//now compare some roots
//	targetnode = targetnode.get_child_by_name("asx");
//	targetnode = targetnode.get_child_by_name("title");
//	sourcenode = sourcenode.get_child_by_name("asx");
//	sourcenode = sourcenode.get_child_by_name("title");
//	//print("\nsource: %s sz: %d\n", sourcenode.text, (int)sourcenode.text.size());
//	//print("\ntarget: %s sz: %d\n", targetnode.text, (int)targetnode.text.size());
//	return sourcenode.text == targetnode.text; 
return true;
}

////   HELPER FUNCTIONS TO DISPLAY NODE DATA IN TERMINAL
//inline void do_n_spaces(ref int dpth) {
//	for(int i = 0; i< dpth; i++)
//		print(" ");
//}
//void show_node_data(Xnoise.SimpleXml.Node? mrnode, ref int dpth) {
//	if(mrnode == null)
//		return;
//	foreach(Xnoise.SimpleXml.Node node in mrnode) {
//		do_n_spaces(ref dpth);
//		print("%s ", node.name);
//		foreach(string s in node.attributes.key_list)
//			print("A:%s=%s ", s, node.attributes[s]);
//		if(node.has_text())
//			print("text=%s\n", node.text);
//		else
//			print("\n");
//		dpth += 2;
//		show_node_data(node, ref dpth);
//	}
//	dpth -= 2;
//}


void test_async_xml_read() {
	File source = File.new_for_path("./playlist-examples/asx_test.asx");
	var mr = new Xnoise.SimpleXml.Reader(source);
	mr.finished.connect(xml_async_finished_cb01);
	mr.ref(); //prevent destruction
	mr.read_asyn.begin(); // all data is now in mr.root if read was successful
}
void xml_async_finished_cb01(Xnoise.SimpleXml.Reader sender) {
	if(sender.root == null)
		print("test async xml reading 01 with errors\n");

	Xnoise.SimpleXml.Node sourcenode = sender.root;
	if(sourcenode == null) {
		print("sourcenode is null\n");
		print("\033[50Gfail\n");
	}
	else {
		sourcenode = sourcenode.get_child_by_name("asx");
		sourcenode = sourcenode.get_child_by_name("title");
		if(sourcenode.text == "Example.com Live Stream")
			print("\033[50Gpass\n");
		else
			print("\033[50Gfail\n");
	}
	sender.unref();
	ml.quit();
	return;
}



void test_m3u_async_reading() {
	File f = File.new_for_path("./playlist-examples/test_m3u.m3u");
	var asxreader = new Xnoise.Pl.Reader();
	asxreader.finished.connect(m3u_async_finished_cb01);
	asxreader.ref(); //prevent destruction
	try {
		asxreader.read_asyn.begin(f.get_uri());
		
	}
	catch(Error e) {
		print("m3u async test error reading\n");
		return;
	}
	return;// uris[0] == t1.get_uri();// && reader.get_number_of_entries() == 5;
}
void m3u_async_finished_cb01(Xnoise.Pl.Reader sender, string pluri) {
//	File t1 = File.new_for_commandline_arg("mms://67.159.60.125/baladas");
	var uris = sender.get_found_uris();
	if(uris[0] == "http://media.example.com/entire.ts" && sender.get_number_of_entries() == 1)
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
	sender.unref();
	ml.quit();
	return;
}


void test_wpl_async_reading() {
	File f = File.new_for_path("./playlist-examples/wpl_test.wpl");
	var wplreader = new Xnoise.Pl.Reader();
	wplreader.finished.connect(wpl_async_finished_cb01);
	wplreader.ref(); //prevent destruction
	try {
		wplreader.read_asyn.begin(f.get_uri());
		
	}
	catch(Error e) {
		print("wpl async test error reading\n");
		return;
	}
	return;// uris[0] == t1.get_uri();// && reader.get_number_of_entries() == 5;
}
void wpl_async_finished_cb01(Xnoise.Pl.Reader sender, string pluri) {
//	File t1 = File.new_for_commandline_arg("mms://67.159.60.125/baladas");
	var uris = sender.get_found_uris();
	if(uris[0] == "mms://win40nj.audiovideoweb.com/avwebdsnjwinlive4051" && sender.get_number_of_entries() == 3)
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
	sender.unref();
	ml.quit();
	return;
}

void test_xspf_async_reading() {
	File f = File.new_for_path("./playlist-examples/xspf.xspf");
	var xspfreader = new Xnoise.Pl.Reader();
	xspfreader.finished.connect(xspf_async_finished_cb01);
	xspfreader.ref(); //prevent destruction
	try {
		xspfreader.read_asyn.begin(f.get_uri());
		
	}
	catch(Error e) {
		print("wpl async test error reading\n");
		return;
	}
	return;// uris[0] == t1.get_uri();// && reader.get_number_of_entries() == 5;
}
void xspf_async_finished_cb01(Xnoise.Pl.Reader sender, string pluri) {
//	File t1 = File.new_for_commandline_arg("mms://67.159.60.125/baladas");
	var uris = sender.get_found_uris();
	if(uris[0] == "http://www.example.com/music/bar.ogg" && sender.get_number_of_entries() == 2)
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
	sender.unref();
	ml.quit();
	return;
}

void main() {
	print("\n");
	// CREATE READER
	print("test reader creation:");
	if(test_reader_creation())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	// RECOGNIZE M3U TYPE
	print("test m3u type recognition:");
	if(test_m3u_type_recognition())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	// RECOGNIZE PLS TYPE
	print("test pls type recognition:");
	if(test_pls_type_recognition())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	// RECOGNIZE XSPF TYPE
	print("test xspf type recognition:");
	if(test_xspf_type_recognition())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	// RECOGNIZE ASX TYPE
	print("test asx type recognition:");
	if(test_asx_type_recognition())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	// RECOGNIZE WPL TYPE
	print("test wpl type recognition:");
	if(test_wpl_type_recognition())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	// READ M3U
	print("test m3u reading:");
	if(test_m3u_reading())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
		
	// READ M3U 2
	print("test m3u reading 2:");
	if(test_m3u_reading_2())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
	
	print("test asx remote reading:");
	if(test_asx_remote_reading())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	print("test asx bad xml remote reading:");
	if(test_asx_bad_xml_remote_reading())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//READ PLS
	//	print("test pls reading:");
	//	if(test_pls_reading())
	//		print("\033[50Gpass\n");
	//	else
	//		print("\033[50Gfail\n");

	//READ PLS
	print("test pls reading 2:");
	if(test_pls_reading_2())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
		
	//READ ASX
	print("test asx reading:");
	if(test_asx_reading())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//READ WPL
	print("test wpl reading:");
	if(test_wpl_reading())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//READ XSPF
	print("test xspf reading:");
	if(test_xspf_reading())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

//	//WRITE ASX
//	print("test asx writing abs paths:");
//	if(test_asx_writing_abs_paths())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");

//	//WRITE M3U
//	print("test m3u writing abs paths:");
//	if(test_m3u_writing_abs_paths())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");

//	//WRITE PLS
//	print("test pls writing abs paths:");
//	if(test_pls_writing_abs_paths())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");

//	//WRITE XSPF
//	print("test xspf writing abs paths:");
//	if(test_xspf_writing_abs_paths())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");


//	//TODO: Relative paths
//	//WRITE ASX
//	print("test asx writing rel paths:");
//	if(test_asx_writing_rel_paths())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");

//	//WRITE M3U
//	print("test m3u writing rel paths:");
//	if(test_m3u_writing_rel_paths())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");

//	//WRITE PLS
//	print("test pls writing rel paths:");
//	if(test_pls_writing_rel_paths())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");

//	//WRITE XSPF
//	print("test xspf writing rel paths:");
//	if(test_xspf_writing_rel_paths())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");

//	//TARGETTYPE ASX
//	print("test asx readwrite targettype:");
//	if(test_asx_readwrite_targettype())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");

//	//TARGETTYPE M3U
//	print("test m3u readwrite targettype:");
//	if(test_m3u_readwrite_targettype())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");

//	//TARGETTYPE PLS
//	print("test pls readwrite targettype:");
//	if(test_pls_readwrite_targettype())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");
/*
	//TARGETTYPE XSPF
	print("test xspf readwrite targettype:");
	if(test_xspf_readwrite_targettype())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
*/
		
//	//PLAYLIST CONVERSION ASX -> XSPF
//	print("test conversion asx -> xspf:");
//	if(test_conversion_asx_xspf())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");
//		

//	//PLAYLIST CONVERSION wpl -> asx
//	print("test conversion wpl -> asx:");
//	if(test_conversion_wpl_asx())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");

	// Corrupted FILE TESTS
	
	//READ M3U without filename extension
//	print("test read M3U without extension:");
//	if(test_m3u_read_with_no_extension_on_file())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");
//		
//	//READ XSPF without filename extension
//	print("test read XSPF without extension:");
//	if(test_xpsf_read_with_no_extension_on_file())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");
//	
//	// async tests
//	
//	print("test pls async reading:");
//	test_pls_async_reading();
//	ml = new MainLoop(); // reuse mainloop for every async test
//	ml.run();

//	print("test xml reading and writing:");
//	if(test_xml_readwrite_01())
//		print("\033[50Gpass\n");
//	else
//		print("\033[50Gfail\n");

//	print("test asx async reading:");
//	test_asx_async_reading();
//	ml = new MainLoop(); // reuse mainloop for every async test
//	ml.run();

//	print("test async xml reading:");
//	test_async_xml_read();
//	ml = new MainLoop(); // reuse mainloop for every async test
//	ml.run();

//	print("test m3u async reading:");
//	test_m3u_async_reading();
//	ml = new MainLoop(); // reuse mainloop for every async test
//	ml.run();

//	print("test wpl async reading:");
//	test_wpl_async_reading();
//	ml = new MainLoop(); // reuse mainloop for every async test
//	ml.run();

//	print("test xspf async reading:");
//	test_xspf_async_reading();
//	ml = new MainLoop(); // reuse mainloop for every async test
//	ml.run();

}

