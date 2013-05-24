/* xnoise-cdda-item-handler.vala
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
 *     Jörn Magens
 */


using Xnoise;
using Xnoise.ExtDev;
using Xnoise.Resources;


private abstract class Xnoise.HandlerCddaDevice : ItemHandler {
//    private Action a;
//    private Action c;
    
    protected unowned CddaDevice device;
    protected unowned Cancellable cancellable;
    private string name;
    
    
    public HandlerCddaDevice(CddaDevice device,
                             Cancellable cancellable) {
        this.device = device;
        this.cancellable = cancellable;
        name = device.get_identifier();
        
//        a = new Action();
//        a.action = add_to_device;
//        a.info = get_add_info();
//        a.name = get_add_name();
//        a.stock_item = Gtk.Stock.OPEN;
//        a.context = ActionContext.QUERYABLE_TREE_MENU_QUERY;
//        
//        c = new Action();
//        c.action = delete_from_device;
//        c.info = get_del_info();
//        c.name = get_del_name();
//        c.stock_item = Gtk.Stock.DELETE;
//        c.context = ActionContext.EXTERNAL_DEVICE_LIST;
    }
    
    
    public override ItemHandlerType handler_type() {
        return ItemHandlerType.EXTERNAL_DEVICE;
    }
    
    public override unowned string handler_name() {
        return name;
    }

    public override unowned Action? get_action(ItemType type,
                                               ActionContext context,
                                               ItemSelectionType selection = ItemSelectionType.NOT_SET) {
//        if(context == ActionContext.QUERYABLE_TREE_MENU_QUERY) {
//            if(device.in_loading || device.in_data_transfer)
//                return null;
//            return a;
//        }
//        if(context == ActionContext.EXTERNAL_DEVICE_LIST) {
//            if(device.in_loading || device.in_data_transfer)
//                return null;
//            return c;
//        }
        return null;
    }
}

