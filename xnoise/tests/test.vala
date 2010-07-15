using Pl;

bool test_reader_creation() {
	var reader = new Pl.Reader();
	return reader != null;
}

bool test_m3u_type_recognition() {
	File f = File.new_for_path("./playlist-examples/test_m3u.m3u");
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
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
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("pls test error reading\n");
		return false;
	}
	return reader.ptype == ListType.PLS;
}

bool test_asx_type_recognition() {
	File f = File.new_for_path("./playlist-examples/asx_test.asx");
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("asx test error reading\n");
		return false;
	}
	return reader.ptype == ListType.ASX;
}

bool test_xspf_type_recognition() {
	File f = File.new_for_path("./playlist-examples/xspf.xspf");
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("xspf test error reading\n");
		return false;
	}
	return reader.ptype == ListType.XSPF;
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
	var uris = reader.get_found_uris();
	//print("Size: %s\n", uris.length.to_string());
	return uris[0] == "http://media.example.com/entire.ts" && reader.get_number_of_entries() == 1;
}

bool test_m3u_reading_2() {
	File f = File.new_for_path("./playlist-examples/test_ext_m3u.m3u");
	File t1 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("m3u test error reading\n");
		return false;
	}
	var uris = reader.get_found_uris();
	//print("Size: %s\n", uris.length.to_string());
	return uris[0] == t1.get_uri() && reader.get_number_of_entries() == 5;
}

//   fails because resource is offline
//bool test_pls_reading() {
//	File f = File.new_for_uri("http://emisora.fundingue.com:8070/listen.pls");
//	var reader = new Pl.Reader();
//	try {
//		reader.read(f.get_uri());
//	}
//	catch(Error e) {
//		print("pls test error reading\n");
//		return false;
//	}
//	var uris = reader.get_found_uris();
//	//print("Size: %s\n", uris.length.to_string());
//	//print("Url0: %s\n",uris[0]);
//	return uris[0] == "http://emisora.fundingue.com:8070/";
//}

bool test_pls_reading_2() {
	File f = File.new_for_path("./playlist-examples/pls_test.pls");
	File t1 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	File t5 = File.new_for_commandline_arg("http://www.site.com:8000/listen.pls");
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
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
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("asx test error reading\n");
		return false;
	}
	var uris = reader.get_found_uris();
	//print("Size: %s\n", uris.length.to_string());
	return uris[0] == "http://example.com/announcement.wma";
}

bool test_xspf_reading() {
	File f = File.new_for_path("./playlist-examples/xspf.xspf");
	File t1 = File.new_for_commandline_arg("/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
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

bool test_asx_writing_abs_paths() {
	File f = File.new_for_path("./playlist-examples/tmp_asx.asx");
	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	string current_title_1 = "BUSCANDO UN FINAL";
	string current_title_2 = "everclear - SMFTA";
	var writer = new Pl.Writer(ListType.ASX, true);
	
	DataCollection data_collection = new DataCollection();
	
	var data = new Data();
	data.add_field(Data.Field.URI, t1.get_uri());
	data.add_field(Data.Field.TITLE, current_title_1);
	data_collection.append(data);
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.add_field(Data.Field.TITLE, current_title_2);
	data_collection.append(data);
	
	try {
		writer.write(data_collection, f.get_uri());
	}
	catch(Error e) {
		print("asx test error writing %s\n", e.message);
		return false;
	}
	
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("asx test error readwrite\n");
		return false;
	}
	var uris = reader.get_found_uris();
	return uris[0] == t1.get_uri() && reader.get_title_for_uri(ref uris[1]) == current_title_2;
}

bool test_m3u_writing_abs_paths() {
	File f = File.new_for_path("./playlist-examples/tmp_m3u.m3u");
	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	string current_title_1 = "BUSCANDO UN FINAL";
	string current_title_2 = "everclear - SMFTA";
	var writer = new Pl.Writer(ListType.M3U, true);
	
	DataCollection data_collection = new DataCollection();
	
	var data = new Data();
	data.add_field(Data.Field.URI, t1.get_uri());
	data.add_field(Data.Field.TITLE, current_title_1); //titles are still ignored
	data_collection.append(data);
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.add_field(Data.Field.TITLE, current_title_2); //titles are still ignored
	data_collection.append(data);
	
	try {
		writer.write(data_collection, f.get_uri());
	}
	catch(Error e) {
		print("m3u test error writing %s\n", e.message);
		return false;
	}
	
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("m3u test error readwrite\n");
		return false;
	}
	var uris = reader.get_found_uris();
	return uris[0] == t1.get_uri() && reader.get_title_for_uri(ref uris[1]) == current_title_2;
}

bool test_pls_writing_abs_paths() {
	File f = File.new_for_path("./playlist-examples/tmp_pls.pls");
	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	string current_title_1 = "BUSCANDO UN FINAL";
	string current_title_2 = "everclear - SMFTA";
	var writer = new Pl.Writer(ListType.PLS, true);
	
	DataCollection data_collection = new DataCollection();
	
	var data = new Data();
	data.add_field(Data.Field.URI, t1.get_uri());
	data.add_field(Data.Field.TITLE, current_title_1); //titles are still ignored
	data_collection.append(data);
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.add_field(Data.Field.TITLE, current_title_2); //titles are still ignored
	data_collection.append(data);
	
	try {
		writer.write(data_collection, f.get_uri());
	}
	catch(Error e) {
		print("pls test error writing %s\n", e.message);
		return false;
	}
	
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("pls test error readwrite\n");
		return false;
	}
	var uris = reader.get_found_uris();
	//print("uris[1] get title: %s\n", reader.get_title_for_uri(ref uris[1])); //Title is empty
	return uris[0] == t1.get_uri() && reader.get_title_for_uri(ref uris[1]) == current_title_2;
}

bool test_xspf_writing_abs_paths() {
	File f = File.new_for_path("./playlist-examples/tmp_xspf.xspf");
	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	string current_title_1 = "BUSCANDO UN FINAL";
	string current_title_2 = "everclear - SMFTA";
	var writer = new Pl.Writer(ListType.XSPF, true);
	
	DataCollection data_collection = new DataCollection();
	
	var data = new Data();
	data.add_field(Data.Field.URI, t1.get_uri());
	data.add_field(Data.Field.TITLE, current_title_1); //titles are still ignored
	data_collection.append(data);
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.add_field(Data.Field.TITLE, current_title_2); //titles are still ignored
	data_collection.append(data);
	
	try {
		writer.write(data_collection, f.get_uri());
	}
	catch(Error e) {
		print("xspf test error writing %s\n", e.message);
		return false;
	}
	
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("xspf test error readwrite\n");
		return false;
	}
	var uris = reader.get_found_uris();
	//print("uris[1] get title: %s\n", reader.get_title_for_uri(ref uris[1])); //Title is empty
	return uris[0] == t1.get_uri() && reader.get_title_for_uri(ref uris[1]) == current_title_2;
}


bool test_asx_writing_rel_paths() {
	File f = File.new_for_path("./playlist-examples/tmp_asx.asx");
	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	string current_title_1 = "BUSCANDO UN FINAL";
	string current_title_2 = "everclear - SMFTA";
	var writer = new Pl.Writer(ListType.ASX, true);
	
	//print("\nuri1: %s\n", t1.get_uri());
	//print("uri2: %s\n", t2.get_uri());
	DataCollection data_collection = new DataCollection();
	
	var data = new Data();
	data.add_field(Data.Field.URI, t1.get_uri());
	data.add_field(Data.Field.TITLE, current_title_1);
	data.target_type = TargetType.ABS_PATH;
	data_collection.append(data);
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.add_field(Data.Field.TITLE, current_title_2);
	data.target_type = TargetType.REL_PATH;
	data_collection.append(data);
	
	try {
		writer.write(data_collection, f.get_uri());
	}
	catch(Error e) {
		print("asx test error writing %s\n", e.message);
		return false;
	}
	
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("asx test error readwrite\n");
		return false;
	}
	var uris = reader.get_found_uris();
	File tmp0 = File.new_for_uri(uris[0]);
	File tmp1 = File.new_for_uri(uris[1]);
	//print("\n#0 %s\n",uris[0]);
	//print("#x %s\n",uris[1]);
	//print("#1 %s\n", tmp0.get_path());
	//print("#2 %s\n", t1.get_path());
	//print("#3 %s\n", f.get_parent().get_relative_path(tmp1));
	//print("#4 %s\n", f.get_parent().get_relative_path(t1));
	return tmp0.get_path() == t1.get_path() && f.get_relative_path(tmp1) == f.get_relative_path(t2);
}

bool test_m3u_writing_rel_paths() {
	File f = File.new_for_path("./playlist-examples/tmp_m3u.m3u");
	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	string current_title_1 = "BUSCANDO UN FINAL";
	string current_title_2 = "everclear - SMFTA";
	var writer = new Pl.Writer(ListType.M3U, true);
	
	//print("\nuri1: %s\n", t1.get_uri());
	//print("uri2: %s\n", t2.get_uri());
	DataCollection data_collection = new DataCollection();
	
	var data = new Data();
	data.add_field(Data.Field.URI, t1.get_uri());
	data.add_field(Data.Field.TITLE, current_title_1);
	data.target_type = TargetType.ABS_PATH;
	data_collection.append(data);
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.add_field(Data.Field.TITLE, current_title_2);
	data.target_type = TargetType.REL_PATH;
	data_collection.append(data);
	
	try {
		writer.write(data_collection, f.get_uri());
	}
	catch(Error e) {
		print("m3u test error writing %s\n", e.message);
		return false;
	}
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("m3u test error readwrite\n");
		return false;
	}
	var uris = reader.get_found_uris();
	File tmp0 = File.new_for_uri(uris[0]);
	File tmp1 = File.new_for_uri(uris[1]);
	//print("#1 %s\n", tmp0.get_path());
	//print("#2 %s\n", t1.get_path());
	//print("#3 %s\n", f.get_parent().get_relative_path(tmp1));
	//print("#4 %s\n", f.get_parent().get_relative_path(t1));
	return tmp0.get_path() == t1.get_path() && f.get_relative_path(tmp1) == f.get_relative_path(t2);
}

bool test_pls_writing_rel_paths() {
	File f = File.new_for_path("./playlist-examples/tmp_pls.pls");
	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	string current_title_1 = "BUSCANDO UN FINAL";
	string current_title_2 = "everclear - SMFTA";
	var writer = new Pl.Writer(ListType.PLS, true);
	
	//print("\nuri1: %s\n", t1.get_uri());
	//print("uri2: %s\n", t2.get_uri());
	DataCollection data_collection = new DataCollection();
	
	var data = new Data();
	data.add_field(Data.Field.URI, t1.get_uri());
	data.add_field(Data.Field.TITLE, current_title_1);
	data.target_type = TargetType.ABS_PATH;
	data_collection.append(data);
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.add_field(Data.Field.TITLE, current_title_2);
	data.target_type = TargetType.REL_PATH;
	data_collection.append(data);
	
	try {
		writer.write(data_collection, f.get_uri());
	}
	catch(Error e) {
		print("pls test error writing %s\n", e.message);
		return false;
	}
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("pls test error readwrite\n");
		return false;
	}
	var uris = reader.get_found_uris();
	File tmp0 = File.new_for_uri(uris[0]);
	File tmp1 = File.new_for_uri(uris[1]);
	//print("#1 %s\n", tmp0.get_path());
	//print("#2 %s\n", t1.get_path());
	//print("#3 %s\n", f.get_parent().get_relative_path(tmp1));
	//print("#4 %s\n", f.get_parent().get_relative_path(t1));
	return tmp0.get_path() == t1.get_path() && f.get_relative_path(tmp1) == f.get_relative_path(t2);
}

bool test_xspf_writing_rel_paths() {
	File f = File.new_for_path("./playlist-examples/tmp_xspf.xspf");
	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	string current_title_1 = "BUSCANDO UN FINAL";
	string current_title_2 = "everclear - SMFTA";
	var writer = new Pl.Writer(ListType.XSPF, true);
	
	//print("\nuri1: %s\n", t1.get_uri());
	//print("uri2: %s\n", t2.get_uri());
	DataCollection data_collection = new DataCollection();
	
	var data = new Data();
	data.add_field(Data.Field.URI, t1.get_uri());
	data.add_field(Data.Field.TITLE, current_title_1);
	data.target_type = TargetType.ABS_PATH;
	data_collection.append(data);
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.add_field(Data.Field.TITLE, current_title_2);
	data.target_type = TargetType.REL_PATH;
	data_collection.append(data);
	
	try {
		writer.write(data_collection, f.get_uri());
	}
	catch(Error e) {
		print("pls test error writing %s\n", e.message);
		return false;
	}
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("pls test error readwrite\n");
		return false;
	}
	var uris = reader.get_found_uris();
	File tmp0 = File.new_for_uri(uris[0]);
	File tmp1 = File.new_for_uri(uris[1]);
	//print("\n%s\n", uris[0]);
	//print("%s\n", uris[1]);
	//print("#1 %s\n", tmp0.get_path());
	//print("#2 %s\n", t1.get_path());
	//print("#3 %s\n", f.get_parent().get_relative_path(tmp1));
	//print("#4 %s\n", f.get_parent().get_relative_path(t1));
	return tmp0.get_path() == t1.get_path() && f.get_relative_path(tmp1) == f.get_relative_path(t2);
}

bool test_asx_readwrite_targettype() {
	File f = File.new_for_path("./playlist-examples/tmp_asx.asx");
	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	string current_title_1 = "BUSCANDO UN FINAL";
	string current_title_2 = "everclear - SMFTA";
	var writer = new Pl.Writer(ListType.ASX, true);
	
	//print("\nuri1: %s\n", t1.get_uri());
	//print("uri2: %s\n", t2.get_uri());
	DataCollection data_collection = new DataCollection();
	
	var data = new Data();
	data.add_field(Data.Field.URI, t1.get_uri());
	data.add_field(Data.Field.TITLE, current_title_1);
	data.target_type = TargetType.ABS_PATH;
	data_collection.append(data);
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.add_field(Data.Field.TITLE, current_title_2);
	data.target_type = TargetType.REL_PATH;
	data_collection.append(data);
	
	try {
		writer.write(data_collection, f.get_uri());
	}
	catch(Error e) {
		print("asx test error writing %s\n", e.message);
		return false;
	}
	
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("asx test error readwrite\n");
		return false;
	}
	TargetType[] tts = {};
	foreach(Data d in reader.data_collection) {
		tts += d.target_type;
	}
	//print("\n%s\n", tts[0].to_string());
	//print("%s\n", tts[1].to_string());
	return tts[0]==TargetType.ABS_PATH && tts[1]==TargetType.REL_PATH;
}

bool test_m3u_readwrite_targettype() {
	File f = File.new_for_path("./playlist-examples/tmp_m3u.m3u");
	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	string current_title_1 = "BUSCANDO UN FINAL";
	string current_title_2 = "everclear - SMFTA";
	var writer = new Pl.Writer(ListType.M3U, true);
	
	//print("\nuri1: %s\n", t1.get_uri());
	//print("uri2: %s\n", t2.get_uri());
	DataCollection data_collection = new DataCollection();
	
	var data = new Data();
	data.add_field(Data.Field.URI, t1.get_uri());
	data.add_field(Data.Field.TITLE, current_title_1);
	data.target_type = TargetType.ABS_PATH;
	data_collection.append(data);
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.add_field(Data.Field.TITLE, current_title_2);
	data.target_type = TargetType.REL_PATH;
	data_collection.append(data);
	
	try {
		writer.write(data_collection, f.get_uri());
	}
	catch(Error e) {
		print("asx test error writing %s\n", e.message);
		return false;
	}
	
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("asx test error readwrite\n");
		return false;
	}
	TargetType[] tts = {};
	foreach(Data d in reader.data_collection) {
		tts += d.target_type;
	}
	//print("\n%s\n", tts[0].to_string());
	//print("%s\n", tts[1].to_string());
	return tts[0]==TargetType.ABS_PATH && tts[1]==TargetType.REL_PATH;
}


bool test_pls_readwrite_targettype() {
	File f = File.new_for_path("./playlist-examples/tmp_pls.pls");
	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	string current_title_1 = "BUSCANDO UN FINAL";
	string current_title_2 = "everclear - SMFTA";
	var writer = new Pl.Writer(ListType.PLS, true);
	
	//print("\nuri1: %s\n", t1.get_uri());
	//print("uri2: %s\n", t2.get_uri());
	DataCollection data_collection = new DataCollection();
	
	var data = new Data();
	data.add_field(Data.Field.URI, t1.get_uri());
	data.add_field(Data.Field.TITLE, current_title_1);
	data.target_type = TargetType.ABS_PATH;
	data_collection.append(data);
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.add_field(Data.Field.TITLE, current_title_2);
	data.target_type = TargetType.URI;
	data_collection.append(data);
	
	try {
		writer.write(data_collection, f.get_uri());
	}
	catch(Error e) {
		print("asx test error writing %s\n", e.message);
		return false;
	}
	
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("asx test error readwrite\n");
		return false;
	}
	TargetType[] tts = {};
	foreach(Data d in reader.data_collection) {
		tts += d.target_type;
	}
	//print("\n%s\n", tts[0].to_string());
	//print("%s\n", tts[1].to_string());
	return tts[0]==TargetType.ABS_PATH && tts[1]==TargetType.URI;
}


bool test_xspf_readwrite_targettype() {
	File f = File.new_for_path("./playlist-examples/tmp_xspf.xspf");
	File t1 = File.new_for_commandline_arg("./playlist-examples/media/Disco de datos/Musica/ILONA-BUSCANDO UN FINAL.ogg");
	File t2 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	string current_title_1 = "BUSCANDO UN FINAL";
	string current_title_2 = "everclear - SMFTA";
	var writer = new Pl.Writer(ListType.XSPF, true);
	
	//print("\nuri1: %s\n", t1.get_uri());
	//print("uri2: %s\n", t2.get_uri());
	DataCollection data_collection = new DataCollection();
	
	var data = new Data();
	data.add_field(Data.Field.URI, t1.get_uri());
	data.add_field(Data.Field.TITLE, current_title_1);
	data.target_type = TargetType.ABS_PATH;
	data_collection.append(data);
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.add_field(Data.Field.TITLE, current_title_2);
	data.target_type = TargetType.REL_PATH;
	data_collection.append(data);
	
	
	data = new Data();
	data.add_field(Data.Field.URI, t2.get_uri());
	data.target_type = TargetType.URI;
	data_collection.append(data);

	try {
		writer.write(data_collection, f.get_uri());
	}
	catch(Error e) {
		print("xspf test error writing %s\n", e.message);
		return false;
	}
	
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("xspf test error readwrite\n");
		return false;
	}
	TargetType[] tts = {};
	foreach(Data d in reader.data_collection) {
		tts += d.target_type;
	}
	//print("\n%s\n", tts[0].to_string());
	//print("%s\n", tts[1].to_string());
	return tts[0]==TargetType.ABS_PATH && tts[1]==TargetType.REL_PATH && tts[2]==TargetType.URI;
}

bool test_conversion_asx_xspf() {
	File f = File.new_for_path("./playlist-examples/asx_test.asx");
	File target = File.new_for_path("./playlist-examples/tmp_copy_as_xspf.xspf");
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
	}
	catch(Error e) {
		print("asx test error reading\n");
		return false;
	}
	DataCollection d = reader.data_collection;
	var writer = new Pl.Writer(ListType.XSPF, true);
	try {
		writer.write(d, target.get_uri());
	}
	catch(Error e) {
		print("asx test error writing %s\n", e.message);
		return false;
	}
	return true; //TODO Howto verify that conversion worked? Maybe do a chain over all types and compare both ends
}

bool test_m3u_read_with_no_extension_on_file() {
	File f = File.new_for_path("./playlist-examples/test_ext_m3u");
	File t1 = File.new_for_commandline_arg("./playlist-examples/Alternative/everclear - SMFTA.mp3");
	var reader = new Pl.Reader();
	try {
		reader.read(f.get_uri());
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
	var reader = new Pl.Reader();
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


	//READ XSPF
	print("test xspf reading:");
	if(test_xspf_reading())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//WRITE ASX
	print("test asx writing abs paths:");
	if(test_asx_writing_abs_paths())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//WRITE M3U
	print("test m3u writing abs paths:");
	if(test_m3u_writing_abs_paths())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//WRITE PLS
	print("test pls writing abs paths:");
	if(test_pls_writing_abs_paths())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//WRITE XSPF
	print("test xspf writing abs paths:");
	if(test_xspf_writing_abs_paths())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");


	//TODO: Relative paths
	//WRITE ASX
	print("test asx writing rel paths:");
	if(test_asx_writing_rel_paths())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//WRITE M3U
	print("test m3u writing rel paths:");
	if(test_m3u_writing_rel_paths())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//WRITE PLS
	print("test pls writing rel paths:");
	if(test_pls_writing_rel_paths())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//WRITE XSPF
	print("test xspf writing rel paths:");
	if(test_xspf_writing_rel_paths())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//TARGETTYPE ASX
	print("test asx readwrite targettype:");
	if(test_asx_readwrite_targettype())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//TARGETTYPE M3U
	print("test m3u readwrite targettype:");
	if(test_m3u_readwrite_targettype())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//TARGETTYPE PLS
	print("test pls readwrite targettype:");
	if(test_pls_readwrite_targettype())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");

	//TARGETTYPE XSPF
	print("test xspf readwrite targettype:");
	if(test_xspf_readwrite_targettype())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
		
	//PLAYLIST CONVERSION ASX -> XSPF
	print("test conversion asx -> xspf:");
	if(test_conversion_asx_xspf())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
		


	// Corrupted FILE TESTS
	
	//READ M3U without filename extension
	print("test read M3U without extension:");
	if(test_m3u_read_with_no_extension_on_file())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
		
	//READ XSPF without filename extension
	print("test read XSPF without extension:");
	if(test_xpsf_read_with_no_extension_on_file())
		print("\033[50Gpass\n");
	else
		print("\033[50Gfail\n");
	
	
}

