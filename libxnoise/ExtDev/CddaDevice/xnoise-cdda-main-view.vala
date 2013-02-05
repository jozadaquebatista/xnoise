/* xnoise-cdda-main-view.vala
 *
 * Copyright (C) 2013  Jörn Magens
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
using Xnoise.Resources;


private class Xnoise.ExtDev.CddaMainView : DeviceMainView {
    private CddaTreeView treeview;
    private Label info_label;
    
    public CddaMainView(CddaDevice dev,
                        Cancellable cancellable) {
        base(dev, cancellable);
        setup_widgets();
    }
    
    
    public override string get_view_name() {
        return device.get_identifier();
    }
    
    protected override string get_localized_name() {
        return _("Audio CD");
    }
    
    private void setup_widgets() {
        
        var box = new Gtk.Box(Orientation.VERTICAL, 0);
        var header_label = new Label("");
        header_label.set_markup("<span size=\"xx-large\"><b>" +
                         Markup.printf_escaped(get_localized_name()) +
                         "</b></span>"
        );
        box.pack_start(header_label, false, false, 12);
        
        info_label = new Label("");
        box.pack_start(info_label, false, false, 4);
        
        treeview = new CddaTreeView(device);
        
        var sw = new ScrolledWindow(null, null);
        sw.set_shadow_type(ShadowType.IN);
        sw.add(treeview);
        box.pack_start(sw, true, true, 0);
        
        var spinner = new Spinner();
        //spinner.start();
        spinner.set_size_request(160, 160);
        add_overlay(spinner);
        spinner.halign = Align.CENTER;
        spinner.valign = Align.CENTER;
        spinner.set_no_show_all(true);
        show();
        spinner.show(); 
        treeview.notify["in-loading"].connect( () => {
            if(treeview.in_loading) {
                spinner.start();
                spinner.set_no_show_all(false);
                spinner.show_all();
            }
            else {
                spinner.stop();
                spinner.hide();
                spinner.set_no_show_all(true);
            }
        });
        
        this.add(box);
    }
}

