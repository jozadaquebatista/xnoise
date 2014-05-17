using TagInfo;
using Xnoise;


[DBus(name = "org.gtk.xnoise.ImageExtractor")]
public class ImageExtractorDbus : GLib.Object {
    private Queue<string> queue = new Queue<string>();
    private unowned DBusConnection conn;
    private unowned ImageExtractorService parent;
    
    public signal void found_image(string artist, string album, string image);
    
    private const string INTERFACE_NAME = "org.gtk.xnoise.ImageExtractor";
    
    
    public ImageExtractorDbus(DBusConnection conn, ImageExtractorService parent) {
        this.conn = conn;
        this.parent = parent;
    }
    
    
    public string ping() {
        parent.refresh_quit_timeout(); // delay app quit
        return "pong";
    }
    
    private uint handle_uris_source = 0;
    private void handle_uris() {
        if(handle_uris_source != 0)
            Source.remove(handle_uris_source);
        handle_uris_source = Timeout.add_seconds(5, () => {
            handle_uris_source = 0;
            Idle.add(handle_each_uri);
            return false;
        });
    }
    
    private uint32 cnt = 0;
    
    private bool handle_each_uri() {
        parent.refresh_quit_timeout(); // delay app quit
        
        string? uri;
        
        while((uri = queue.pop_head()) != null) {
            string u = uri;
            Idle.add(() => {
                parent.refresh_quit_timeout(); // delay app quit
                File f = File.new_for_uri(u);
                if(f == null || f.get_path() == null)
                    return false;
                //print("handle file number %u\n", ++cnt);
                handle_single_file(f);
                return false;
            });
        }
        return false;
    }
    
    private void handle_single_file(File f) {
        Info? info = Info.create(f.get_path());
        if(info == null)
            return;
        if(!info.load())
            return;
        string artist = ((info.albumartist != null && info.albumartist != "") ? 
                            info.albumartist : 
                            info.artist);
        string album  = info.album;
        
        if(artist == null || artist == "" ||
           album == null || album == "") {
            print("no valid data for %s\n", f.get_path());
            return;
        }
        
//        uint8[] data;
        Image.FileType image_type = Image.FileType.JPEG;
        Gdk.Pixbuf? pixbuf = null;
        
        if(info.has_image) {
            File? pf  = get_albumimage_for_artistalbum(artist, album, "embedded");
            File? pf2 = get_albumimage_for_artistalbum(artist, album, "extralarge");
            
            if(pf == null)
                return;
            
            if(pf.query_exists(null) && pf2.query_exists(null))
                return;
            
            Image[] images = info.get_images();
            if(images != null && images.length > 0) {
                var pbloader = new Gdk.PixbufLoader();
                try {
                    pbloader.write(images[0].get_data());
                }
                catch(Error e) {
                    print("Error 1: %s\n", e.message);
                    try { pbloader.close(); } catch(Error e) { print("Error 2\n");}
                }
                try { 
                    pbloader.close(); 
                    pixbuf = pbloader.get_pixbuf();
                } 
                catch(Error e) { 
                    print("Error 3 for %s :\n\t %s\n", f.get_path(), e.message);
                    return;
                }
            }
            if(pixbuf != null) {
                save_pixbuf_to_file(artist, album, pixbuf, image_type);
            }
        }
        else {
            File? pf = get_albumimage_for_artistalbum(artist, album, "medium");
            if(pf == null) {
                //print("handle_single_file pf null for %s - %s\n", artist, album);
                return;
            }
            if(pf.query_exists(null))
                return;
            try_find_image_in_folder(f, artist, album);
        }
    }
    
    private void save_pixbuf_to_file(string artist,
                                     string album,
                                     Gdk.Pixbuf pixbuf,
                                     Image.FileType image_type) {
        if(pixbuf != null) {
            File? pf2 = null;
            File? pf = get_albumimage_for_artistalbum(artist, album, "embedded");
            if(pf == null) {
                return;
            }
            string itype;
            switch(image_type) {
                case Image.FileType.BMP:
                    itype = "bmp";
                    break;
                case Image.FileType.GIF:
                    itype = "gif";
                    break;
                case Image.FileType.PNG:
                    itype = "png";
                    break;
                case Image.FileType.JPEG:
                default:
                    itype = "jpeg";
                    break;
            }
            if(!pf.query_exists(null)) {
                try {
                    File parentpath = pf.get_parent();
                    if(!parentpath.query_exists(null))
                        parentpath.make_directory_with_parents(null);
                    pixbuf.save(pf.get_path(), itype);
                }
                catch(Error e) {
                    print("%s\n", e.message);
                    return;
                }
            }
            pf2 = File.new_for_path(pf.get_path().replace("_embedded", "_extralarge"));
            if(!pf2.query_exists(null)) {
                try {
                    pixbuf.save(pf2.get_path(), itype);
                    found_image(artist, album, pf2.get_path());
                }
                catch(Error e) {
                    print("%s\n", e.message);
                    return;
                }
            }
            pf2 = File.new_for_path(pf.get_path().replace("_embedded", "_medium"));
            if(!pf2.query_exists(null)) {
                try {
                    pixbuf.save(pf2.get_path(), itype);
                }
                catch(Error e) {
                    print("%s\n", e.message);
                    return;
                }
            }
        }
    }
    
    private void try_find_image_in_folder(File f,
                                          string artist,
                                          string album) {
        
        File? pf = get_albumimage_for_artistalbum(artist, album, "medium");
        var folder = f.get_parent();
        FileEnumerator enumerator;
        string attr = FileAttribute.STANDARD_NAME + "," +
                      FileAttribute.STANDARD_TYPE + "," +
                      FileAttribute.STANDARD_CONTENT_TYPE;
        try {
            enumerator = folder.enumerate_children(attr, FileQueryInfoFlags.NONE);
        } 
        catch(Error e) {
            print("Error importing directory %s. %s\n", folder.get_path(), e.message);
            return;
        }
        GLib.FileInfo fileinfo;
        try {
            while((fileinfo = enumerator.next_file()) != null) {
                TrackData td = null;
                string filename = fileinfo.get_name();
                string filepath = Path.build_filename(folder.get_path(), filename);
                File file = File.new_for_path(filepath);
                FileType filetype = fileinfo.get_file_type();
                if(filetype == FileType.DIRECTORY) {
                    continue;
                }
                else {
                    string uri_lc = filename.down();
                    string mime = GLib.ContentType.get_mime_type(fileinfo.get_content_type());
                    if((mime == "image/png" ||
                        mime == "image/jpeg" ||
                        mime == "image/jpg") &&
                       (filename.down() == "folder.jpeg" ||
                        filename.down() == "folder.png" ||
                        filename.down().contains("cover") ||
                        filename.down().contains("album"))) {
                        
                        File parentpath = pf.get_parent();
                        if(!parentpath.query_exists(null))
                            parentpath.make_directory_with_parents(null);
                        bool success = false;
                        if(!pf.query_exists(null)) {
                            try {
                                file.copy(pf, FileCopyFlags.NONE, null, null);
                                success = true;
                            }
                            catch(Error e) {
                                print("%s\n", e.message);
                            }
                        }
                        File pf2 = File.new_for_path(pf.get_path().replace("_medium", "_extralarge"));
                        if(!pf2.query_exists(null)) {
                            try {
                                file.copy(pf2, FileCopyFlags.NONE, null, null);
                            }
                            catch(Error e) {
                                print("%s\n", e.message);
                            }
                        }
                        if(success)
                            found_image(artist, album, pf2.get_path());
                        
                        break;
                    }
                }
            }
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
    }
    
    public void add_uris(string[] uris) {
        parent.refresh_quit_timeout(); // delay app quit
        foreach(string uri in uris) {
            queue.push_head(uri);
        }
        handle_uris();
    }
}

public class ImageExtractorService : GLib.Object {
    internal static MainLoop loop;
    private uint owner_id;
    private uint object_id_service;
    private ImageExtractorDbus service = null;
    private unowned DBusConnection conn;
    private const int QUIT_TIMEOUT = 80;
    
    
    public ImageExtractorService() {
        refresh_quit_timeout();
    }
    
    public void setup_dbus() {
        owner_id = Bus.own_name(BusType.SESSION,
                                "org.gtk.xnoise.ImageExtractor",
                                 GLib.BusNameOwnerFlags.NONE,
                                 on_bus_acquired,
                                 on_name_acquired,
                                 on_name_lost);
        assert(owner_id != 0);
        refresh_quit_timeout();
    }
    
    ~ImageExtractorService() {
        clean_up();
    }
    
    
    private void on_bus_acquired(DBusConnection connection, string name) {
        //print("bus acquired : %s\n", name);
        this.conn = connection;
        try {
            service = new ImageExtractorDbus(connection, this);
            object_id_service = connection.register_object("/ImageExtractor", service);
        }
        catch(IOError e) {
            print("%s\n", e.message);
        }
    }

    private void on_name_acquired(DBusConnection connection, string name) {
        //print("name acquired: %s\n", name);
    }    
    
    private void on_name_lost(DBusConnection connection, string name) {
//        loop.quit();
        //print("name_lost: %s\n", name);
    }
    
    private uint quit_timeout_source = 0;
    
    internal void refresh_quit_timeout() {
        if(quit_timeout_source != 0)
            Source.remove(quit_timeout_source);
        quit_timeout_source = Timeout.add_seconds(QUIT_TIMEOUT, () => {
            print("DONE\n"); // after 60 of inactivity
            loop.quit();
	    quit_timeout_source = 0;
            return false;
        });
    }
    
    private void clean_up() {
        if(owner_id == 0)
            return;
        Bus.unown_name(owner_id);
        owner_id = 0;
    }
    
    
    public static int main(string[] args) {
        var ser = new ImageExtractorService();
        ser.setup_dbus();
        loop = new MainLoop(null, false);
        loop.run();
        return 0;
    }
}

