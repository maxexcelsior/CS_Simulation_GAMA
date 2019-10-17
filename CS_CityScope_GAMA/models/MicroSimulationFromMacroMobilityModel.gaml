model microFromMacro

global {

	string city<-'Detroit';
	map<string, string> table_name_per_city <- ['Detroit'::'corktown', 'Hamburg'::'grasbrook'];
	string city_io_table<-table_name_per_city[city];

	file od_file <- json_file("https://cityio.media.mit.edu/api/table/"+city_io_table+"/od");	
	file meta_grid_file <- geojson_file("https://cityio.media.mit.edu/api/table/"+city_io_table+"/meta_grid","EPSG:4326");	
	file table_area_file <- geojson_file("https://raw.githubusercontent.com/CityScope/CS_Mobility_Service/master/scripts/cities/"+city+"/clean/table_area.geojson");
	file walking_net_file<-geojson_file("https://raw.githubusercontent.com/CityScope/CS_Mobility_Service/master/scripts/cities/"+city+"/clean/walking_net.geojson");
	file cycling_net_file<-geojson_file("https://raw.githubusercontent.com/CityScope/CS_Mobility_Service/master/scripts/cities/"+city+"/clean/cycling_net.geojson");
	file driving_net_file<-geojson_file("https://raw.githubusercontent.com/CityScope/CS_Mobility_Service/master/scripts/cities/"+city+"/clean/driving_net.geojson");
	file pt_net_file<-geojson_file("https://raw.githubusercontent.com/CityScope/CS_Mobility_Service/master/scripts/cities/"+city+"/clean/pt_net.geojson");
	file portals_file<-geojson_file("https://raw.githubusercontent.com/CityScope/CS_Mobility_Service/master/scripts/cities/"+city+"/clean/portals.geojson");
	
	
	
	graph walking_graph;
	graph cycling_graph;
	graph driving_graph;
	graph pt_graph;
	map<int, graph> graph_map <-[0::driving_graph, 1::cycling_graph, 2::walking_graph, 3::pt_graph];
	
	
	geometry shape <- envelope(meta_grid_file);
	geometry free_space <- copy(shape);
	bool simple_landuse<-true;
	
	
	//LANDUSE FOR CORKTOWN (https://data.detroitmi.gov/app/parcel-viewer-2)
	map<string, rgb> string_type_per_landuse <- ["B1"::rgb(161,80,98),"B2"::rgb(190,60,94),"B3"::rgb(218,26,91),"B4"::rgb(153,0,51),"B5"::rgb(130,16,54),"B6"::rgb(96,0,21),
	"M1"::rgb(133,84,157),"M2"::rgb(144,72,183),"M3"::rgb(155,55,209),"M4"::rgb(93,32,128),"M5"::rgb(101,0,151),
	"P1"::rgb(95,152,61),"PC"::rgb(95,152,61),"PCA"::rgb(95,152,61),"PD"::rgb(95,152,61),"PR"::rgb(95,152,61),
	"R1"::rgb(109,129,159),"R2"::rgb(77,130,197),"R3"::rgb(16,131,237),"R4"::rgb(11,83,176),"R5"::rgb(30,83,141),"R6"::rgb(8,45,121),
	"SD1"::rgb(185,105,40),"SD2"::rgb(185,105,40),"SD4"::rgb(185,105,40),"SD5"::rgb(185,105,40),"TM"::rgb(185,105,40),"W1"::rgb(185,105,40)	
	];
	//map<string, rgb> string_type_per_landuse_Simple <- ["B"::rgb(161,80,98),"M"::rgb(133,84,157),"P"::rgb(95,152,61),"R"::rgb(109,129,159),"S"::rgb(185,105,40),nil::#black];
	map<string, rgb> string_type_per_landuse_Simple <- ["B"::rgb(0,0,255),"M"::rgb(255,0,0),"P"::rgb(0,255,0),"R"::rgb(255,255,0),"S"::rgb(0,255,255),nil::#black];
	map<string, string> detailed_to_simple_landuse <- ["B1"::"B","B2"::"B","B3"::"B","B4"::"B","B5"::"B","B6"::"B","M1"::"M","M2"::"M","M3"::"M","M4"::"M","M5"::"M",
	"P1"::"P","PC"::"P","PCA"::"P","PD"::"P","PR"::"P","R1"::"R","R2"::"R","R3"::"R","R4"::"R","R5"::"R","R6"::"R","SD1"::"S","SD2"::"S","SD4"::"S","SD5"::"S","TM"::"S","W1"::"S"];
	
	//MODE PARAMETERS
	map<int, rgb> color_type_per_mode <- [0::#black, 1::#gamared, 2::#gamablue, 3::#gamaorange];
	map<int, string> string_type_per_mode <- [0::"driving", 1::"cycling", 2::"walking", 3::"transit"];
	map<int, float> speed_per_mode <- [0::30.0, 1::15.0, 2::5.0, 3::10.0];
	//Profile
	map<int, rgb> color_type_per_type <- [0::#gamared, 1::#gamablue, 2::#gamaorange];
	map<int, string> string_type_per_type <- [0::"live and works here ", 1::"works here", 2::"lives here"];
	
	float step <- 10 #sec;
	int saveLocationInterval<-500;
	
	bool showLegend parameter: 'Show Legend' category: "Parameters" <-true;
	bool showLandUse parameter: 'Show Landuse' category: "Parameters" <-true; 
	bool showMode parameter: 'Show Mode' category: "Parameters" <-true; 
    bool showRoad parameter: 'Show Road' category: "Parameters" <-true; 
	
	init {
		create areas from: table_area_file;
		create portal from: portals_file;
		create block from:meta_grid_file with:[land_use::read("land_use")]{
			if(simple_landuse){
				land_use<-detailed_to_simple_landuse[land_use];
			}
			if(land_use!=nil){
				//free_space <- free_space - shape;
			}
		}
		create road from: driving_net_file{
			type<-0;
		}
		create road from: cycling_net_file{
			type<-1;
		}
		create road from: walking_net_file{
			type<-2;
		}
		create road from: pt_net_file{
			type<-3;
		}
		driving_graph <- as_edge_graph(road where (each.type=0));
		cycling_graph <- as_edge_graph(road where (each.type=1));
		walking_graph <- as_edge_graph(road where (each.type=2));
		pt_graph <- as_edge_graph(road where (each.type=3));
		do initiatePeople;	
			
	}
	
	action initiatePeople{
		  ask people{
		    do die;
		  }
		  loop lo over: od_file {
			loop l over: list(lo) {
				map m <- map(l);
				create people with: [type::int(m["type"]), mode::int(m["mode"]), home::point(m["home_ll"]), work::point(m["work_ll"]), start_time::int(m["start_time"])] {
					location <- home;
					home <- point(to_GAMA_CRS(home, "EPSG:4326"));
					work <- point(to_GAMA_CRS(work, "EPSG:4326"));
			        location<-home;
				}
			}
		  }	
		  create pedestrian number:200{
		  	location<-any_location_in(one_of(areas));
		  }
    }
	//6AM to 12pm=> 
	reflex save_results when: (cycle=6480){//(time = 8640/(2*step))  {
		string t;
		map<string, unknown> test;
		
		
		save "[" to: "result.json";
		ask pedestrian {
			test <+ "mode"::mode;
			test<+"path"::locs;
			//test<+locs;
			t <- "{\n\"mode\": "+rnd(2)+",\n\"path\": [";
			int curLoc<-0;
			loop l over: locs {
				
				point loc <- CRS_transform(l).location;
				if(curLoc<length(locs)-1){
				t <- t + "[" + loc.x + ", " + loc.y + "],\n";	
				}else{
				t <- t + "[" + loc.x + ", " + loc.y + "]\n";	
				}
				curLoc<-curLoc+1;
			}
			t <- t + "]";
			t <- t+",\n\"timestamps\": [";
			curLoc<-0;
			loop l over: locs {
				
				point loc <- CRS_transform(l).location;
				if(curLoc<length(locs)-1){
				t <- t + loc.z + ",\n";	
				}else{
				t <- t +  loc.z + "\n";	
				}
				curLoc<-curLoc+1;
			}
			t <- t + "]";
			
			
			t<- t+ "\n}";
			if (int(self) < (length(pedestrian) - 1)) {
				t <- t + ",";
			}
			save t to: "result.json" rewrite: false;
		}

		save "]" to: "result.json" rewrite: false;
		file JsonFileResults <- json_file("./result.json");
        map<string, unknown> c <- JsonFileResults.contents;
        write "c" + c;
        write "test" + test;
		try{			
	  	  save(json_file("https://cityio.media.mit.edu/api/table/update/"+city_io_table+"/ABM", c));		
	  	}catch{
	  	  write #current_error + " Impossible to write to cityIO - Connection to Internet lost or cityIO is offline";	
	  	}
	}
	
	reflex updateSimulationStatus{

	}
}


species block{
	string land_use;
	aspect base {
		if(showLandUse){
		  draw shape color: simple_landuse ? string_type_per_landuse_Simple[land_use]: string_type_per_landuse[land_use];	
		}
	}
	
}

species areas {
	rgb color <- rnd_color(255);
	rgb text_color <- (color.brighter);
	
	aspect default {
		draw shape color: #gray;
	}
}

species portal{
	aspect base {
		draw circle(50#m) color: #gamablue;
	}
}


species people skills:[moving]{
	int mode;
	int type;
	int start_time;
	point home;
	point work;
	
	rgb color <- rnd_color(255);
	list<point> locs;
		
	reflex move{
		if(time>start_time and location!=work){
			if (mode=0) {do goto target:work speed:0.01 * speed_per_mode[mode] on: driving_graph;}
			else if (mode=1) {do goto target:work speed:0.01 * speed_per_mode[mode] on: cycling_graph;}
			else if (mode=2) {do goto target:work speed:0.01 * speed_per_mode[mode] on: walking_graph;}
			else if (mode=3) {do goto target:work speed:0.01 * speed_per_mode[mode] on: pt_graph;} 
		}
		if(time mod saveLocationInterval = 0 and time>1 and location!=work){
		 	locs << {location.x,location.y,time};
		}	
	}

	aspect base {
		if(showMode){
		  draw circle(10#m) color: color_type_per_mode[mode] border:color_type_per_mode[mode]-50;	
		}else{
		  draw circle(10#m) color: color_type_per_type[type] border:color_type_per_mode[mode]-50;	
		}
		
	}
}


species pedestrian skills: [pedestrian]{
	point current_target;
	int mode<-2;
	list<point> locs;
	reflex choose_target when: current_target = nil {
		current_target <- any_location_in(one_of(people));
	}
	reflex move when: current_target != nil{
		do walk target: current_target bounds: free_space speed:0.01;
		if (self distance_to current_target < 0.1) {
			current_target <- any_location_in(one_of(people));
		}
		if(time mod saveLocationInterval = 0 and time>1){
		 	locs << {location.x,location.y,time};
		}	
	}
	
	aspect base{
		draw triangle(10) color:#gamablue border:#gamablue-50;
	}
}

species road schedules: [] {
	int type;
	aspect default {
		if(showRoad){
		  draw shape color: color_type_per_mode[type] width:2;	
		}	
	}
}


experiment Dev type: gui autorun:true{
	output {
		display map_mode type:opengl background:#black{	
			//species areas refresh:false;
			species block aspect:base;
			species road;
			species people aspect:base;
			species pedestrian aspect:base;	
			species portal aspect:base;
			event["b"] action: {showLandUse<-!showLandUse;};
			event["l"] action: {showLegend<-!showLegend;};
			event["m"] action: {showMode<-!showMode;};
			event["r"] action: {showRoad<-!showRoad;};
			overlay position: { 5, 5 } size: { 180 #px, 100 #px } background: # black transparency: 0.5 border: #black rounded: true
            {
            	if(showLegend){
	            	float y <- 30#px;
	            	if(showMode){
	            	  loop mode over: color_type_per_mode.keys
	                	{
	                    draw square(10#px) at: { 20#px, y } color: color_type_per_mode[mode] border: #white;
	                    draw string(string_type_per_mode[mode]) at: { 40#px, y + 4#px } color: # white font: font("SansSerif", 18, #bold);
	                    y <- y + 25#px;
	                	}	
	            	}else{
	            		loop type over: color_type_per_type.keys
		                {
		                    draw square(10#px) at: { 20#px, y } color: color_type_per_type[type] border: #white;
		                    draw string(string_type_per_type[type]) at: { 40#px, y + 4#px } color: # white font: font("SansSerif", 18, #bold);
		                    y <- y + 25#px;
		                }
	            	}	                
            	}
            }
		}
	}
}