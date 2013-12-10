/* xnoise-audio-player-device.vala
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

using Gtk;

using Xnoise;
using Xnoise.ExtDev;



public class Xnoise.ExtDev.DeviceManager : GLib.Object {
    
    private GLib.VolumeMonitor volume_monitor;
    private HashTable<string,Device> devices;
    private List<DeviceIdContainer> callbacks = new List<DeviceIdContainer>();
    
    public delegate Device? IdentificationCallback(Mount mount);
    
    public class DeviceIdContainer {
        public unowned IdentificationCallback cb;
        public DeviceIdContainer(IdentificationCallback cb) {
            this.cb = cb;
        }
    }
    
    public DeviceManager() {
        lock(devices) {
            devices = new HashTable<string,Device>(str_hash, str_equal);
        }
        
        //register device types
        register_device(new DeviceIdContainer(AndroidPlayerDevice.get_device));
        register_device(new DeviceIdContainer(GenericPlayerDevice.get_device));
        register_device(new DeviceIdContainer(CddaDevice.get_device));
        
        volume_monitor = VolumeMonitor.get();
        
        volume_monitor.mount_added.connect( (s,m) => {
            this.mount_added(m);
        });
        volume_monitor.mount_removed.connect( (s,m) => {
            this.mount_removed(m);
        });
        
        check_existing_mounts();
    }
    
    public void register_device(DeviceIdContainer c) {
        callbacks.prepend(c);
    }
    
    private void check_existing_mounts() {
        foreach(Mount m in volume_monitor.get_mounts()) {
            Idle.add( () => {
                mount_added(m);
                return false;
            });
        }
    }
    
    private void mount_added(Mount mount) {
        assert(mount != null);
        if(mount.get_volume() == null)
            return;
        var job = new Worker.Job(Worker.ExecutionType.ONCE, mount_added_job);
        job.set_arg("mount", mount);
        device_worker.push_job(job);
    }
    
    private bool mount_added_job(Worker.Job job) {
        Mount? mount = (Mount)job.get_arg("mount");
        if(mount.get_volume() == null)
            return false;
        assert(mount != null);
        Device? d = null;
        lock(devices) {
            d = devices.lookup(mount.get_default_location().get_uri());
        }
        if(d != null)
            return false;  // already here
        
        d = null;
        foreach(DeviceIdContainer c in callbacks) {
            if((d = c.cb(mount)) != null) {
                break;
            }
        }
        if(d != null) {
            if(d.initialize()) {
                lock(devices) {
                    devices.insert(d.get_identifier(), d);
                }
                Idle.add(() => {
                    main_window.mainview_box.add_main_view(d.get_main_view_widget());
                    main_window.main_view_sbutton.insert(d.get_identifier(), d.get_presentable_name(), d.get_icon());
                    ItemHandler? handler = null;
                    if((handler = d.get_item_handler()) != null)
                        itemhandler_manager.add_handler(handler);
                    
                    //Idle.add(() => {
                    //    main_window.main_view_sbutton.select(d.get_identifier(), true);
                    //    return false;
                    //});
                    return false;
                });
            }
            else {
                mount_removed(mount);
            }
        }
        else {
            print ("unknown device in %s\n", mount.get_default_location().get_parse_name());
        }
        return false;
    }
    
    private void mount_removed(Mount mount) {
        Device? d = null;
        lock(devices) {
            d = devices.lookup(mount.get_default_location().get_uri());
        }
        if(d == null)
            return;
        
        d.cancel();
        itemhandler_manager.remove_handler(d.get_item_handler());
//        devices.remove(d.get_identifier());
        main_window.main_view_sbutton.del(d.get_identifier());
        main_window.mainview_box.remove_main_view(d.get_main_view_widget());
        lock(devices) {
            devices.remove(mount.get_default_location().get_uri());
        }
    }
}

