/* xnoise-media-monitor.vala
 *
 * Copyright (C) 2012 - 2013  Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  The Xnoise authors hereby grant permission for non-GPL compatible
 *  GStreamer plugins to be used and distributed together with GStreamer
 *  and Xnoise. This permission is above and beyond the permissions granted
 *  by the GPL license by which Xnoise is covered. If you modify this code
 *  you may extend this exception to your version of the code, but you are not
 *  obligated to do so. If you do not wish to do so, delete this exception
 *  statement from your version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author:
 *     Jörn Magens <shuerhaaken@googlemail.com>
 */


using Xnoise;


public class Xnoise.MediaMonitor : GLib.Object {
    
    private class Event {
        public enum ChangeType {
            CHANGED_FILE,
            DELETED_FILE,
            DELETED_DIR,
            ADDED_FILE,
            ADDED_DIR
        }
        
        public string? path;
        public ChangeType type;
        
        public Event(ChangeType type, string path) {
            this.type  = type;
            this.path  = path;
        }
    }
    
    private HashTable<string, FileMonitor> monitors;

    private MainContext local_context;
    private MainLoop local_loop;
    
    private HashTable<string, Event> event_table = new HashTable<string, Event> (str_hash, str_equal);

    private unowned Thread<int> thread;
    
    public MediaMonitor() {
        if (!Thread.supported ()) {
            error("Cannot work without multithreading support.");
        }
        
        try {
            thread = Thread.create<int>(thread_func, false);
        }
        catch(ThreadError e) {
            print("Error creating thread: %s\n", e.message);
        }
        Source source = new TimeoutSource(2000); 
        source.set_callback(() => {
            setup_monitors();
            return false;
        });
        source.attach(local_context);
    }
    
    private int thread_func() {
        local_context = new MainContext();
        local_context.push_thread_default();
        local_loop = new MainLoop(local_context);
        local_loop.run();
        return 0;
    }

    private void on_changed(FileMonitor sender,
                            File file,
                            File? other_file,
                            FileMonitorEvent event_type) {
        //print("local thread used is %s \n", ((void*)Thread.self<int>() == (void*)thread).to_string());
        //print("file: %s :: %s\n", file.get_basename(), event_type.to_string());
        if(sender.cancelled)
            return;
        switch(event_type) {
            case FileMonitorEvent.CHANGED:
                if(global.media_import_in_progress)
                    return;
                if(!monitors.contains(file.get_path())) {
                    if(!event_table.contains(file.get_path()))
                        event_table.insert(file.get_path(), 
                                           new Event(Event.ChangeType.CHANGED_FILE, file.get_path()));
                    event_table_changed();
                }
                break;
            case FileMonitorEvent.CREATED:
                if(file.query_file_type(FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY) {
                    add_monitor_for_directory(file);
                    event_table.insert(file.get_path(), 
                                       new Event(Event.ChangeType.ADDED_DIR, file.get_path()));
                }
                else {
                    event_table.insert(file.get_path(), 
                                       new Event(Event.ChangeType.ADDED_FILE, file.get_path()));
                }
                event_table_changed();
                break;
            case FileMonitorEvent.DELETED:
                if(monitors.contains(file.get_path())) { // DIRS
                    monitors.remove(file.get_path());
                    if(event_table.contains(file.get_path()))
                        event_table.remove(file.get_path());
                    
                    event_table.insert(file.get_path(), 
                                       new Event(Event.ChangeType.DELETED_DIR, file.get_path()));
                }
                else { // FILES
                    if(event_table.contains(file.get_path()))
                        event_table.remove(file.get_path());
                    
                    event_table.insert(file.get_path(), 
                                       new Event(Event.ChangeType.DELETED_FILE, file.get_path()));
                }
                event_table_changed();
                break;
            case FileMonitorEvent.MOVED:
                if(monitors.contains(file.get_path())) {
                    monitors.remove(file.get_path());
                    add_monitor_for_directory(other_file);
                    
                    if(event_table.contains(file.get_path()))
                        event_table.remove(file.get_path());
                    
                    event_table.insert(file.get_path(), 
                                       new Event(Event.ChangeType.DELETED_DIR, 
                                                             file.get_path()));
                    
                    event_table.insert(other_file.get_path(), 
                                       new Event(Event.ChangeType.ADDED_DIR, 
                                                             other_file.get_path()));
                }
                else {
                    bool temp_file = false;
                    if(event_table.contains(file.get_path())) {
                        if(event_table.lookup(file.get_path()).type == Event.ChangeType.ADDED_FILE) {
                            temp_file = true;
                        }
                        event_table.remove(file.get_path());
                    }
                    if(temp_file) {
                        event_table.insert(other_file.get_path(), 
                                           new Event(Event.ChangeType.CHANGED_FILE, 
                                                                 other_file.get_path()));
                    }
                    else {
                        event_table.insert(file.get_path(), 
                                           new Event(Event.ChangeType.DELETED_FILE, 
                                                                 file.get_path()));
                        event_table.insert(other_file.get_path(), 
                                           new Event(Event.ChangeType.ADDED_FILE, 
                                                                 other_file.get_path()));
                    }
                }
                event_table_changed();
                break;
            default: break;
        }
    }
    
    private uint handler_id = 0;
    
    private void event_table_changed() {
        if(handler_id != 0) {
            Source s = local_context.find_source_by_id(handler_id);
            s.destroy();
        }
        Source source = new TimeoutSource(1000); 
        source.set_callback( () => {
            if(MainContext.current_source().is_destroyed()) {
                //print("current source removed\n");
                return false;
            }
            HashTable<string, Event> local_event_table = event_table;
            event_table = new HashTable<string, Event>(str_hash, str_equal);
            List<Event> list = local_event_table.get_values();
            
            string[] add_uris = {};
            string[] remove_uris = {};
            string[] reimport_uris = {};
            
            foreach(Event e in list) {
                assert(e.path != null);
                print("EVHT: %s  ::  %s\n", e.path, e.type.to_string());
                switch(e.type) {
                    case Event.ChangeType.ADDED_DIR:
                        File folder = File.new_for_path(e.path);
                        Item item = Item(ItemType.LOCAL_FOLDER, folder.get_uri());
                        media_importer.add_import_target_folder(item, false);
                        break;
                    case Event.ChangeType.DELETED_DIR:
                        File folder = File.new_for_path(e.path);
                        Item item = Item(ItemType.LOCAL_FOLDER, folder.get_uri());
                        media_importer.remove_folder_item(item);
                        break;
                    case Event.ChangeType.CHANGED_FILE:
                        File file = File.new_for_path(e.path);
                        reimport_uris += file.get_uri();
                        break;
                    case Event.ChangeType.ADDED_FILE:
                        File file = File.new_for_path(e.path);
                        add_uris += file.get_uri();
                        break;
                    case Event.ChangeType.DELETED_FILE:
                        File file = File.new_for_path(e.path);
                        remove_uris += file.get_uri();
                        break;
                    default: break;
                }
            }
            
            if(remove_uris.length != 0)
                media_importer.remove_uris(remove_uris);
            
            if(add_uris.length != 0)
                media_importer.import_uris(add_uris);
            
            if(reimport_uris.length != 0)
                media_importer.reimport_media_files(reimport_uris);
            
            handler_id = 0;
            return false;
        });
        handler_id = source.attach(local_context);
    }

    private void add_monitor_for_directory(File dir){
        try {
            FileMonitor monitor = dir.monitor_directory(FileMonitorFlags.SEND_MOVED);
            monitor.changed.connect(on_changed);
            if(monitors.contains(dir.get_path()))
                warning("file monitor exists for path " + dir.get_path());
            monitors.insert(dir.get_path(), monitor);
        }
        catch(IOError e) {
            print("Media Monitor error: %s\n", e.message);
        }
    }
    
    private void setup_monitors() {
        File dir = File.new_for_path(Environment.get_user_special_dir(UserDirectory.MUSIC));
        monitors = new HashTable<string, FileMonitor>(str_hash, str_equal);
        setup_monitor_recoursive(dir);
        print("Finished setting up file monitors.\n");
    }

    private string attr = FileAttribute.STANDARD_NAME + "," +
                          FileAttribute.STANDARD_TYPE;
    
    private void setup_monitor_recoursive(File dir) {
        if(dir.get_path() == null)
            return;
        if(dir.query_file_type(FileQueryInfoFlags.NONE, null) != FileType.DIRECTORY)
            return;
        add_monitor_for_directory(dir);
        
        FileEnumerator enumerator;
        try {
            enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE);
        } 
        catch(Error e) {
            print("Error reading directory %s: %s\n", dir.get_path(), e.message);
            return;
        }
        GLib.FileInfo info;
        try {
            while((info = enumerator.next_file()) != null) {
                string filename = info.get_name();
                string filepath = Path.build_filename(dir.get_path(), filename);
                File file = File.new_for_path(filepath);
                FileType filetype = info.get_file_type();
                if(filetype == FileType.DIRECTORY)
                    setup_monitor_recoursive(file);
            }
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
    }
}


