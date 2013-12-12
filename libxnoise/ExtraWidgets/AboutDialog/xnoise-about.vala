/* xnoise-about.vala
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


using GLib;

using Xnoise;
using Xnoise.Resources;


private class Xnoise.AboutDialog : Gtk.AboutDialog {

    public AboutDialog() {
        this.set_modal(true);
        this.set_transient_for(main_window);
        this.logo_icon_name = PROGRAM_NAME;
        
        set_default_icon_name(PROGRAM_NAME);
        this.set_logo_icon_name(PROGRAM_NAME);

        this.authors            = AUTHORS;
        this.program_name       = PROGRAM_NAME;
        this.version            = Config.PACKAGE_VERSION;
        this.website            = WEBSITE;
        this.website_label      = "Xnoise media player - Home";
        this.copyright          = COPYRIGHT;
        this.translator_credits = _("translator-credits");
    }
}

