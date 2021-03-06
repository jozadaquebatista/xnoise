/* xnoise-worker.vala
 *
 * Copyright (C) 2009-2013  Jörn Magens
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




public class Xnoise.Worker : Object {
    
    private AsyncQueue<Job> job_queue = new AsyncQueue<Job>();
    
    private unowned MainContext main_context;
    private unowned Thread<int> _thread;
    
    public delegate bool WorkFunc(Job jb);
    public delegate void FinishFunc();
    
    public unowned Thread<int> thread {
        get { return _thread; }
    }
    
    
    public Worker(MainContext mc) {
        if (!Thread.supported ()) {
            error("Cannot work without multithreading support.");
        }
        
        assert(mc != null);
        
        this.main_context = mc;
        
        try {
            _thread = Thread.create<int>(thread_func, false);
        }
        catch(ThreadError e) {
            print("Error creating thread: %s\n", e.message);
        }
    }
    
    
    public bool is_same_thread() {
        return (void*)Thread.self<int>() == (void*)_thread;
    }
    
    public enum Priority {
        NORMAL = 0,
        HIGH
    }
    
    public enum ExecutionType {
        ONCE = 0,
        REPEATED                // repeat until worker function returns false
    }
    
    public class Job {
        private HashTable<string,Value?> ht = new HashTable<string,Value?> (str_hash, str_equal);
        
        public Job(ExecutionType execution_type = ExecutionType.ONCE,
                   WorkFunc? func = null,
                   Priority priority = Priority.NORMAL,
                   FinishFunc? finish_func = null) {
            this.execution_type = execution_type;
            this.func = func;
            this.priority = priority;
            this.finish_func = finish_func;
        }
        
        // using the setter/getter will use a copy of the values for simple types, strings, arrays and structs
        // only for classes a reference is used
        public void set_arg(string? name, owned Value? val) {
            if(name == null)
                return;
            this.ht.insert(name, (owned)val);
        }
        public unowned Value? get_arg(string name) {
            return this.ht.lookup(name);
        }
        
        ~Job() {
            if(this.ht != null)
                this.ht.remove_all();
            //print("dtor job\n"); 
        }
//        private uint _timer_seconds = 0;
        public Priority priority;
        // payload
        public Item? item;
//        public ImportTarget? import_target;
        public Item[] items;
        public FileData[] file_data;
        public string[] uris;
        public TrackData[] track_dat; 
        public DndData[] dnd_data;
        public Gtk.TreeRowReference[] treerowrefs;
        // It is useful to have some Job persistent counters available
        public int counter[4];
        // 4 more big couters
        public int32 big_counter[4];
        
        public ExecutionType execution_type;
        
        public unowned WorkFunc? func = null;
        public unowned FinishFunc? finish_func = null;
        public Cancellable? cancellable = null;
    }
    
    //thread function is used to setup a local mainloop/maincontext
    private int thread_func() {
        Job? current_job = null;
        while(true) {
            current_job = job_queue.pop();
            if(current_job == null) {
                print("no sync job\n");
                return 0;
            }
            while(current_job.func(current_job) &&
                  current_job.execution_type == ExecutionType.REPEATED);
            
            if(current_job.finish_func != null) {
                unowned FinishFunc ff = current_job.finish_func;
                Source s2 = new IdleSource(); 
                s2.set_callback( () => {
                    ff();
                    return false;
                });
                s2.attach(main_context);
            }
        }
        return 0;
    }
    
    private static int compare_func(Job a, Job b) {
        if((int)a.priority == (int)b.priority)
            return 0;
        if((int)a.priority > (int)b.priority)
            return -1;
        return 1;
    }
    
    // After pushing a Job, it will be executed and removed
    public void push_job(Job j) {
        if(j.func == null) {
            print("Error: There must be a WorkFunc in a job.\n");
            return;
        }
        job_queue.push_sorted(j, compare_func);
    }
    
    public int get_queue_length() {
        return job_queue.length();
    }
}

