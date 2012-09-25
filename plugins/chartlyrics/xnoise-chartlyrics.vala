/* xnoise-chartlyrics.vala
 *
 * Copyright (C) 2010  Andreas Obergrusberger
 * Copyright (C) 2011-2012  Jörn Magens
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
 *     Andreas Obergrusberger <softshaker@googlemail.com>
 */
 
// Plugin for chartlyrics.com plugin API


using Soup;
using Xml;

using Xnoise;
using Xnoise.Resources;

using Xnoise.PluginModule;


// XML PARSING DOES NOT YET WORK

public class Xnoise.ChartlyricsPlugin : GLib.Object, IPlugin, ILyricsProvider {
    private unowned PluginModule.Container p;
    private unowned PluginModule.Container _owner;
    
    public Main xn { get; set; }
    
    public PluginModule.Container owner {
        get {
            return _owner;
        }
        set {
            _owner = value;
        }
    }

    public string name {
        get {
            return CHARTLYRICS;
        }
    }

    public string provider_name {
        get {
            return CHARTLYRICS;
        }
    }
    
    public int priority { get; set; default = 1; }
    
    public bool init() {
        priority = 3;
        p = plugin_loader.plugin_htable.lookup("DatabaseLyrics");
        if(p == null) {
            if(this.owner != null)
                Idle.add( () => {
                    owner.deactivate();
                    return false;
                }); 
            return false;
        }
        if(!p.activated)
            plugin_loader.activate_single_plugin(p.info.name);
        
        if(!p.activated) {
            print("cannot start DatabaseLyrics plugin\n");
            if(this.owner != null)
                Idle.add( () => {
                    owner.deactivate();
                    return false;
                }); 
            return false;
        }
        
        p.sign_deactivated.connect(dblyrics_deactivated);
        return true;
    }

    public void uninit() {
        main_window.lyricsView.lyrics_provider_unregister(this); // for lyricsloader
    }

    public Gtk.Widget? get_settings_widget() {
        return null;
    }

    public bool has_settings_widget() {
        return false;
    }
        
    public Xnoise.ILyrics* from_tags(LyricsLoader loader, string artist, string title, LyricsFetchedCallback cb) {
        return (ILyrics*)new Chartlyrics(loader, _owner, artist, title, cb);
    }

    private uint deactivation_source = 0;
    private void dblyrics_deactivated() {
        if(deactivation_source != 0)
            Source.remove(deactivation_source);
        deactivation_source = Idle.add( () => {
            
            if(this.owner != null) {
                Idle.add( () => {
                    owner.deactivate();
                    return false;
                }); 
            }
            return false;
        });
    }
}

private static const string CHARTLYRICS = "Chartlyrics";

public class Xnoise.Chartlyrics : GLib.Object, ILyrics {
    private const int SECONDS_FOR_TIMEOUT = 12;
    private static Session session;
    private Message hid_msg;
    
    private string artist;
    private string title;
        
    private static const string auth = "xnoise";
    private static const string check_url = "http://api.chartlyrics.com/apiv1.asmx/SearchLyric?artist=%s&song=%s";
    private static const string text_url = "http://api.chartlyrics.com/apiv1.asmx/GetLyric?lyricId=%s&lyricCheckSum=%s";
    private static const string xp_hid = "//SearchLyricResult[LyricId != \"\" and LyricChecksum != \"\"]/LyricChecksum";
    private static const string xp_id = "//SearchLyricResult[LyricId != \"\" and LyricChecksum != \"\"]/LyricId";
    private static const string xp_text = "//Lyric";
    
    private string hid;
    private string id;
    private string text;
    private bool? availability;
    private unowned PluginModule.Container owner;
    private unowned LyricsLoader loader;
    private unowned LyricsFetchedCallback cb = null;
    private uint timeout = 0;
    
    public Chartlyrics(LyricsLoader _loader, PluginModule.Container _owner, string artist, string title, LyricsFetchedCallback _cb) {
        this.artist = artist;
        this.title = title;
        this.owner = _owner;
        this.loader = _loader;
        this.cb = _cb;
        
        this.owner.sign_deactivated.connect( () => {
            destruct();
        });
        
        session = new SessionAsync();
        Xml.Parser.init ();
        
        hid = EMPTYSTRING;
        id = EMPTYSTRING;
        
        availability = null;
        
        var gethid_str = new StringBuilder();
        gethid_str.printf(check_url, Soup.URI.encode(artist, null), Soup.URI.encode(title, null));
        
        hid_msg = new Soup.Message("GET", gethid_str.str);
    }
    
    protected bool timeout_elapsed() {
        if(MainContext.current_source().is_destroyed())
            return false;
        
        Idle.add( () => {
            if(this.cb != null)
                this.cb(artist, title, get_credits(), get_identifier(), EMPTYSTRING, CHARTLYRICS);
            return false;
        });
        
        timeout = 0;
        Timeout.add_seconds(1, () => {
            destruct();
            return false;
        });
        return false;
    }

    public uint get_timeout() {
        return timeout;
    }
    
    private bool fetch_hid() {
        uint status;
        status = session.send_message (hid_msg);
        if (status != KnownStatusCode.OK) return false;
        if (hid_msg.response_body.data == null) return false;
        //message((string)hid_msg.response_body.data);
        //print("-------------------HID\n%s\n\n", hid);
        
        
        // Web API call ok, do the xml processing
        string xmltext = (string)hid_msg.response_body.data;
        xmltext = xmltext.replace("<ArrayOfSearchLyricResult xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"http://api.chartlyrics.com/\">", "<ArrayOfSearchLyricResult>");
        xmltext = xmltext.replace("<SearchLyricResult xsi:nil=\"true\" />", EMPTYSTRING);
        //message(xmltext);
        
        Xml.Doc* xmldoc = Xml.Parser.read_doc(xmltext);
        if (xmldoc == null) return false;
        
        XPath.Context xp_cont = new XPath.Context(xmldoc);
        //message(xp_hid);
        var xp_result = xp_cont.eval_expression(xp_hid);
        if (xp_result->nodesetval->is_empty()) { 
            //message("no hid result");
            delete xmldoc;
            availability = false;
            return false;
        }
        
        var hid_result_node = xp_result->nodesetval->item (0);
        if (hid_result_node == null) {
            delete xmldoc;
            availability = false;
            return false;
        }
        
        xp_result = xp_cont.eval_expression(xp_id);
        if (xp_result->nodesetval->is_empty()) { 
            delete xmldoc;
            availability = false;
            return false;
        }
        
        hid = hid_result_node->get_content();
        //message(hid);
        
        var id_result_node = xp_result->nodesetval->item(0);
        if (hid_result_node == null) {
            delete xmldoc;
            availability = false;
            return false;
        }
        id = id_result_node->get_content();
        //message(id);
        delete xmldoc;
        
        if (hid == EMPTYSTRING || id == EMPTYSTRING) {
            availability = false;
            return false;
        }
        
        availability = true;
        return true;
    }
    
    private bool fetch_text() {
        var gettext_str = new StringBuilder();
        gettext_str.printf(text_url, id, hid);
        var text_msg = new Message("GET", gettext_str.str);
        
        uint status;
        status = session.send_message (text_msg);
        
        if (status != KnownStatusCode.OK) return false;
        if (text_msg.response_body.data == null) return false;
        //message((string)text_msg.response_body.data);
        string xmltext = (string)text_msg.response_body.data;
        xmltext = xmltext.replace("<GetLyricResult xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"http://api.chartlyrics.com/\">", "<GetLyricResult>");

        // Web API call ok, do the xml processing
        
        Xml.Doc* xmldoc = Xml.Parser.read_doc(xmltext);
        if (xmldoc == null) return false;
        
        XPath.Context xp_cont = new XPath.Context(xmldoc);
        
        var xp_result = xp_cont.eval_expression(xp_text);
        if (xp_result->nodesetval->is_empty()) {
            //message ("empty"); 
            delete xmldoc;
            availability = false;
            return false;
        }
        
        var text_result_node = xp_result->nodesetval->item (0);
        if (text_result_node == null) {
            //message ("no item");
            delete xmldoc;
            availability = false;
            return false;
        }
        text = text_result_node->get_content();
        //message (text);
        delete xmldoc;
        Idle.add( () => {
            if(this.cb != null)
                this.cb(artist, title, get_credits(), get_identifier(), text, CHARTLYRICS);
            this.destruct();
            return false;
        });
                
        return true;
    }
        
    
//    private bool? available() {
//        return availability;
//    }
    
    public void find_lyrics() {
        fetch_hid();
        fetch_text();
        timeout = Timeout.add_seconds(SECONDS_FOR_TIMEOUT, timeout_elapsed);
    }
    
    public string get_text() {
        return text;
    }
    
    public string get_credits() {
        return "Lyrics provided by chartlyrics.com";
    }
    
    public string get_identifier() {
        return CHARTLYRICS;
    }
}

