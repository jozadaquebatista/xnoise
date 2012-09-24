/* xnoise-main.vala
 *
 * Copyright (C) 2009-2012  Jörn Magens
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
 *     Jörn Magens
 */



public class Xnoise.Main : GLib.Object {
    private static Main _instance;
    internal static Xnoise.Dbus dbus;
    private int _thread_id = 0;
    internal static bool show_plugin_state;
    internal static bool no_plugins;
    internal static bool no_dbus;
    
    internal static unowned Xnoise.Application app;
    
    public int thread_id { get { return _thread_id; } }
    
    public Main() {
        //Gtk.Widget.set_default_direction(Gtk.TextDirection.RTL);
        _instance = this;
        
        _thread_id = (int)Linux.gettid();
        //message( "background worker thread %d", (int)Linux.gettid() );
        
        bool is_first_start;
        Xnoise.initialize(out is_first_start);
        
        userinfo = new UserInfo(main_window.show_status_info);
        
        // ITEM HANDLERS
        itemhandler_manager.add_handler(new HandlerPlayItem());
        itemhandler_manager.add_handler(new HandlerRemoveTrack());
        itemhandler_manager.add_handler(new HandlerAddToTracklist());
        itemhandler_manager.add_handler(new HandlerEditTags());
        itemhandler_manager.add_handler(new HandlerAddAllToTracklist());
        itemhandler_manager.add_handler(new HandlerShowInFileManager());
        itemhandler_manager.add_handler(new HandlerMoveToTrash());
        
        // LOAD PLUGINS
        if(!no_plugins) {
            plugin_loader.load_all();
            
            foreach(string name in Params.get_string_list_value("activated_plugins")) {
                if(!plugin_loader.activate_single_plugin(name))
                    print("\t%s plugin failed to activate!\n", name);
            }
            
            if(show_plugin_state) print(" PLUGIN INFO:\n");
            foreach(string name in plugin_loader.plugin_htable.get_keys()) {
                if((show_plugin_state)&&(plugin_loader.plugin_htable.lookup(name).loaded))
                    if(show_plugin_state)
                        print("\t%s loaded\n", name);
                else {
                    print("\t%s NOT loaded\n\n", name);
                    continue;
                }
                
                if((show_plugin_state)&&(plugin_loader.plugin_htable.lookup(name).activated))
                    print("\t%s activated\n", name);
                else
                    if(show_plugin_state) print("\t%s NOT activated\n", name);
                
                if(show_plugin_state) 
                    print("\n");
            }
            bool tmp = false;
            foreach(string name in plugin_loader.lyrics_plugins_htable.get_keys()) {
                if(plugin_loader.lyrics_plugins_htable.lookup(name).activated == true) {
                    tmp = true;
                    break;
                }
                tmp = false;
            }
            main_window.active_lyrics = tmp;
        }
        
        // POSIX SIGNALS
        connect_signals();
        
        // RESTORE PARAMS IN SUBSCRIBERS
        Params.set_start_parameters_in_implementors();
        
        // LOAD DBUS
        if(!no_dbus) {
            Timeout.add_seconds(2, () => {
                dbus = new Dbus();
                return false;
            });
        }
        
        // FIRST START? Ask to FILL DB!
        if(is_first_start)
            main_window.ask_for_initial_media_import();
        
        // periodically save state and tracklist content
        add_cyclic_save_timeout();
        
        Idle.add(() => {
            main_window.restore_tracks();
            return false;
        });
    }
    
    private uint cyclic_save_source = 0;
    private void add_cyclic_save_timeout() {
        cyclic_save_source = Timeout.add_seconds(60, () => {
            if(MainContext.current_source().is_destroyed())
                return false;
            if(!global.media_import_in_progress && 
               !main_window.musicBr.mediabrowsermodel.populating_model) {
                
                save_tracklist();
                save_activated_plugins();
                Params.write_all_parameters_to_file();
            }
            return true;
        });
    }

    private void connect_signals() {
        Posix.signal(Posix.SIGQUIT, on_posix_finish); // clean up on posix sigquit signal
        Posix.signal(Posix.SIGTERM, on_posix_finish); // clean up on posix sigterm signal
        Posix.signal(Posix.SIGINT,  on_posix_finish); // clean up on posix sigint signal
    }

    public void immediate_play(string uri) {
        Item? item = ItemHandlerManager.create_item(uri);
        if(item.type == ItemType.UNKNOWN) {
            print("itemtype unknown\n");
            return;
        }
        ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
        if(tmp == null)
            return;
        unowned Action? action = tmp.get_action(item.type, ActionContext.REQUESTED, ItemSelectionType.SINGLE);
        
        if(action != null) {
            action.action(item, null);
        }
        else {
            print("action was null\n");
        }
    }

    public static Main instance {
        get {
            if(_instance == null)
                _instance = new Main();
            return _instance;
        }
    }

    private static void on_posix_finish(int signal_number) {
        //print("Posix signal received (%d)\ncleaning up...\n", signal_number);
        instance.quit();
    }

    public void save_activated_plugins() {
        //print("\nsaving activated plugins...\n");
        string[]? activatedplugins = {};
        foreach(string name in plugin_loader.plugin_htable.get_keys()) {
            if(plugin_loader.plugin_htable.lookup(name).activated)
                activatedplugins += name;
        }
        if(activatedplugins.length <= 0)
            activatedplugins = null;
        Params.set_string_list_value("activated_plugins", activatedplugins);
    }

    public void save_tracklist() {
        var job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, media_importer.write_lastused_job);
        job.track_dat = tlm.get_all_tracks();
        job.finished.connect( () => {
            //print("finished db saving\n");
            preparing_quit = false;
        });
        db_worker.push_job(job);
    }
    
    private static bool preparing_quit = false;
    
    private bool quit_job(Worker.Job job) {
        this.app.release();
        return false;
    }
    
    public void quit() {
        global.main_cancellable.cancel();
        global.player_in_shutdown();
        global.player_state = PlayerState.STOPPED;
        Source.remove(cyclic_save_source);
        preparing_quit = true;
        var jx = new Worker.Job(Worker.ExecutionType.TIMED, quit_job, 4);
        io_worker.push_job(jx);
        jx.finished.connect( () => {
            this.app.release();
            preparing_quit = false;
        });
        print ("closing...\n");
        if(main_window.is_fullscreen) 
            main_window.get_window().unfullscreen();
        main_window.hide();
        gst_player.stop();
        this.save_activated_plugins();
        Params.write_all_parameters_to_file();
        this.save_tracklist();
        
        Timeout.add(100, () => {
            if(preparing_quit)
                return true;
            this.app.release();
            return false;
        });
    }
}
