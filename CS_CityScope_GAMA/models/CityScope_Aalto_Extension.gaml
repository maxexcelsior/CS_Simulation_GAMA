/***
* Name: CityScope_ABM_Aalto
* Author: Babak Firoozi Fooladi, Ronan Doorley and Arnaud Grignard
* Description: This is an extension of the orginal CityScope Main model.
* Tags: Tag1, Tag2, TagN
***/

model CityScope_ABM_Aalto

//import "CityScope_main.gaml"

global{
	//GIS folder of the CITY	
	string cityGISFolder <- "./../includes/City/otaniemi";	
	
	// Variables used to initialize the table's grid position.
//	float angle <- -9.74;
//	point center <- {1600, 1000};
//	float brickSize <- 24.0;
//	float cityIOVersion<-2.1;
//	bool initpop <-false;
	
	//	city_io
	string CITY_IO_URL <- "https://cityio.media.mit.edu/api/table/aalto_02";
	string CITY_IO_GRID_DATA_URL <- "https://cityio.media.mit.edu/api/table/aalto_02/grid";
	string CITY_IO_GRID_HASHES_URL <- "https://cityio.media.mit.edu/api/table/aalto_02/meta/hashes";
	// Offline backup data to use when server data unavailable.
	string BACKUP_DATA <- "../includes/City/otaniemi/cityIO_Aalto.json";
	
	file meta_grid_file <- geojson_file("https://cityio.media.mit.edu/api/table/aalto_02/meta_grid","EPSG:4326");
	map<int, int> meta_grid_index_to_grid_data_index;
	map<string, unknown> cityMatrixData;
	
	map<int, map<string,string>> city_matrix_types<-[
		0:: ['usage':: 'None', 'category'::'None', 'capacity':: 'None'],
		1:: ['usage':: 'Residential', 'category'::'R', 'capacity':: '30'],
		2:: ['usage':: 'Residential', 'category'::'R', 'capacity':: '60'],
		3:: ['usage':: 'Residential', 'category'::'R', 'capacity':: '90'],
		4:: ['usage':: 'Residential', 'category'::'S', 'capacity':: '40'],
		5:: ['usage':: 'Residential', 'category'::'S', 'capacity':: '80'],
		6:: ['usage':: 'Residential', 'category'::'S', 'capacity':: '120'],
		7:: ['usage':: 'Parking', 'category'::'None', 'capacity':: '15'],
		8:: ['usage':: 'Parking', 'category'::'None', 'capacity':: '30'],
		9:: ['usage':: 'Parking', 'category'::'None', 'capacity':: '45']	
	];
	string last_hash<-'0';

	
//	// TODO: mapping needs to be fixed for Aalto inputs
//	map<int, list> citymatrix_map_settings <- [-1::["Green", "Green"], 0::["R", "L"], 1::["R", "M"], 2::["R", "S"], 3::["O", "L"], 4::["O", "M"], 5::["O", "S"], 6::["A", "Road"], 7::["A", "Plaza"], 
//		8::["Pa", "Park"], 9::["P", "Parking"], 20::["Green", "Green"], 21::["Green", "Green"]
//	]; 
	
	map<string, string> people_to_housing_types <- ['aalto_staff':: 'R', 'aalto_student':: 'S', 'aalto_visitor'::'NA'];
	
	////////////////////////////////////////////
	//		
	//			USER INPUT VARIABLES
	//
	////////////////////////////////////////////
	
	// Timing and speed of Simulation:
	
	int first_hour_of_day <- 8;
	int last_hour_of_day <- 19;
	
	int seconds_per_day <- 8640;
	int current_hour update: first_hour_of_day + (time / #hour) mod (last_hour_of_day-first_hour_of_day);
	int current_day <- 0;
//	float driving_speed<- 30/3.6; // km/hr to m/s
//	float walking_speed<- 4/3.6; // km/hr to m/s
	map mode_speed_map <- ["walk"::4/3.6, "drive"::30/3.6, 'pt'::20/3.6, 'cycle':: 15/3.6];
	
	float step <- 15 #mn;
	int current_time update: (first_hour_of_day *60) + ((time / #mn) mod ((last_hour_of_day-first_hour_of_day) * 60));
	
	// Multiplication factor for reducing the number of agents
	// This is used to make the simulation lighter especially when the area is big and count of agetns is high
	
	int multiplication_factor <- 20  min:1 max: 50 parameter: "Multiplication factor" category: "people";
	
	//Maximum distance between workspace and the parking
	
	int max_walking_distance <- 300 			min:0 max:3000	parameter: "maximum walking distance form parking:" category: "people settings";
	
	// Staff timing options
	float min_work_start_for_staff <- 8.0		;
	float max_work_start_for_staff <- 10.0		;

	float min_work_duration_for_staff <- 5.0	;
	float max_work_duration_for_staff <- 7.0	;
	
	// Students timing options
	float min_work_start_for_student <- 8.0		;
	float max_work_start_for_student <- 12.0	;

	float min_work_duration_for_student <- 5.0	;
	float max_work_duration_for_student <- 7.0	;
	
	// Visitors timing option
	float min_work_start_for_visitor <- 8.0		;
	float max_work_start_for_visitor <- 14.0	;
	
	float min_work_duration_for_visitor <- 0.5	;
	float max_work_duration_for_visitor <- 2.0	;	
	
	float max_work_start<-max(min_work_start_for_staff, max_work_start_for_student, max_work_start_for_visitor);
	
	// Count of People for each user Groups
	int count_of_staff <- 11000 min:5000 max: 15000 parameter: "number of Aalto staff " category: 	"user group";
	int count_of_students <- 5000 min:3000 max: 8000 parameter: "number of Aalto students" category: "user group";	
	int count_of_visitors <- 1000 min:0 max: 5000 parameter: "number of visitors during the day" category: "user group";
	int baseline_num_parking <- 3000 min:0 max: 5000 parameter: "number of parking spaces at baseline" category: "user group";	
	
	// Interaction Graph
//	bool drawInteraction <- false parameter: "Draw Interaction:" category: "Interaction";
	int distance <- 50 parameter: "Distance:" category: "Interaction" min: 0 max: 200;
	
	//////////////////////////////////////////
	//Style
	////////////////////////////////////////// 
	map my_colors<-['red':: rgb(228,26,28),
		'blue':: rgb(55,126,184),
		'green':: rgb(77,175,74),
		'purple':: rgb(152,78,163),
		'orange':: rgb(255,127,0),
		'yellow':: rgb(255,255,51),
		'brown':: rgb(166,86,40)
	];
	map people_color_map <- ["aalto_student"::my_colors['blue'], "aalto_visitor"::my_colors['purple'],  "aalto_staff"::my_colors['green']];
	map mode_color_map <- ["walk"::my_colors['green'], "drive"::my_colors['brown'], 'pt'::my_colors['yellow'], 'cycle':: my_colors['blue']];
	//////////////////////////////////////////
	//
	// 		FILES LOCATION SECTION:
	//
	//////////////////////////////////////////
	
	
	file parking_footprint_shapefile <- file(cityGISFolder + "/parking_footprint.shp");
	file roads_shapefile <- file(cityGISFolder + "/roads.shp");
	file campus_buildings <- file(cityGISFolder + "/buildings_weighting_rd.geojson");
	file gateways_file <- file(cityGISFolder + "/gateways.shp");
	file bound_shapefile <- file(cityGISFolder + "/Bounds.shp");
		
	//checking time
	//This line ensures that whenever time is changed the clock will be written down.
	

	int clock_display;
	reflex clock_Min when:current_time != clock_display {clock_display <- current_time ; write(string(int(current_time/60)) + ":" + string(current_time mod 60) ) ;
	}

	
	// Supporting variables
	
	string pressure_record <- "time,";
	string capacity_record <- "time,";
	parking recording_parking_sample;
	list<parking> list_of_parkings;
	float total_weight_office;
	float total_weight_parking;
	float total_weight_residential;	
	geometry shape <- envelope(bound_shapefile);	
	graph car_road_graph;
//	graph<aalto_staff, aalto_staff> interaction_graph;
	
	int number_of_people <- count_of_staff + count_of_students + count_of_visitors ;
	int number_staff_and_students <- count_of_staff + count_of_students;

	//////////////////////////////////////////
	//
	// 		INITIALIZATION SECTION:
	//
	//////////////////////////////////////////
	
	bool residence_type_randomness;
	
	action update_grid_data {
		list grid_cell_data;
		write('Checking hash');
		string grid_hash <- json_file(CITY_IO_GRID_HASHES_URL).contents['grid'];
//		if grid_hash!=last_hash{
		if true{
			write('Fetching grid data');
			try {
//				cityMatrixData <- json_file(CITY_IO_URL).contents;
				map grid_data_map <- json_file(CITY_IO_GRID_DATA_URL).contents;
				grid_cell_data<-grid_data_map['contents'];
			}
	
			catch {
				cityMatrixData <- json_file(BACKUP_DATA).contents;
				grid_cell_data <- cityMatrixData["grid"];
				write #current_error + "Connection to Internet lost or cityIO is offline - CityMatrix is a local version";
			}
//			write(cityMatrixData);
			ask parking {
				if self.interactive =true{
					do die;
				}
			}
			ask residential {
				if self.interactive =true{
					do die;
				}
			}
			
			ask grid_cell {
				if self.interactive_id !=nil{
					int usage_id<-grid_cell_data[self.interactive_id][0];
					if city_matrix_types contains_key usage_id{
						if city_matrix_types[usage_id]['usage']='Residential'{
							create residential with: [shape::self.shape,
				     			usage:: 'R',
				     			category:: city_matrix_types[usage_id]['category'],
				     			interactive_id::self.interactive_id,
				     			capacity::int(city_matrix_types[usage_id]['capacity'])/multiplication_factor,
				     			interactive::true];
						}
						if city_matrix_types[usage_id]['usage']='Parking'{
							create parking with: [shape::self.shape,
	//			     			usage:: 'P',
	//			     			category:: city_matrix_types[usage_id]['category'],
				     			interactive_id::self.interactive_id,
				     			total_capacity::max(int(city_matrix_types[usage_id]['capacity'])/multiplication_factor,1),
				     			interactive::true];
						}
					}
				}
			}
			last_hash<-grid_hash;
		
		}
			
	}
	
	init {
		write(step);
		create parking from: parking_footprint_shapefile with: [
			ID::int(read("Parking_id")),
			weight::int(read("Capacity")),
			total_capacity::max(int(read("Capacity"))/multiplication_factor,1), 
			excess_time::int(read("time"))
		];
		list_of_parkings <- list(parking);
		
		create office from: campus_buildings with: [usage::string(read("Usage")), scale::string(read("Scale")), weight::float(read("office_weight_rd")), category::string(read("Category"))] {
			if usage != "O"{
				do die;
			}
			color <- rgb(255,0,0,20);
		}
		
		create residential from: campus_buildings with: [usage::string(read("Usage")), scale::string(read("Scale")), weight::float(read("Weight")), category::string(read("Category")), capacity::int(read("Residents"))] {
			if usage != "R"{
				do die;
			}
			color <- rgb(255,255,0,20);
			if weight = 0 {
				weight <- 1.0;
			}
			
			//TODO Here the capacity is not defined in the SHP file, therefore for the sake of demonstration capacity is set to 1
			// To define the capacity, reading information should be added to the creating residentials line
			
//			capacity <- 1;
			
			capacity <- max(round(capacity / multiplication_factor),1);
		}
		
		create gateways from: gateways_file{
			capacity <- number_of_people;
		}
		
		
		// ------ ADJUSTING THE WEIGHT OF THE BUILDINGS
		// This will produce capacity for working spaces according to their score. so the agents will distribute accordingly.
		// If the capacity is defined by other means, this block of code should change or removed.
		
		total_weight_parking <- sum(parking collect each.weight);
		total_weight_office <- sum(office collect each.weight);
		total_weight_residential <- sum(residential collect each.weight);

		loop i from:0 to:length(list(office))-1{
			office[i].total_capacity <- max(round(((office[i].weight * number_staff_and_students)/total_weight_office)/multiplication_factor),1);
			office[i].capacity <- max(round(((office[i].weight * number_staff_and_students)/total_weight_office)/multiplication_factor),1);
		}
		
		loop i from:0 to:length(list(parking))-1{
			parking[i].total_capacity <- max(round(((parking[i].weight * baseline_num_parking)/total_weight_parking)/multiplication_factor),1);
			parking[i].capacity <- max(round(((parking[i].weight * baseline_num_parking)/total_weight_parking)/multiplication_factor),1);
		}
		
		create car_road from: roads_shapefile;
		car_road_graph <- as_edge_graph(car_road);
		
		//USER GROUP CREATION
		// initial location is set to (0,0) to hide them. since the living space location is initiated later to make agents creating operating
		
		create aalto_staff number: count_of_staff / multiplication_factor {
			location <- {0,0,0};
			time_to_work <- int((min_work_start_for_staff*60 + rnd(max_work_start_for_staff - min_work_start_for_staff)*60));
			time_to_sleep <-int((time_to_work + min_work_duration_for_staff*60 + rnd(max_work_duration_for_staff - min_work_duration_for_staff)*60));
			objective <- "resting";
//			people_color_car 	<- rgb(184,213,67)  ;
//			people_color		<- rgb(238,147,36)  ;
			type_of_agent <- "aalto_staff";
		}		
		
		create aalto_student number: count_of_students / multiplication_factor {
			location <- {0,0,0};
			time_to_work <- int((min_work_start_for_student*60 + rnd(max_work_start_for_student - min_work_start_for_student)*60));
			time_to_sleep <-int((time_to_work + min_work_duration_for_student*60 + rnd(max_work_duration_for_student - min_work_duration_for_student)*60));
			objective <- "resting";
//			people_color_car 	<- rgb(106,189,69)  ;
//			people_color		<- rgb(230,77,61)  ;
			type_of_agent <- "aalto_student";
		}		
		
		create aalto_visitor number: count_of_visitors / multiplication_factor {
			location <- {0,0,0};
			time_to_work <- int((min_work_start_for_visitor*60 + rnd(max_work_start_for_visitor - min_work_start_for_visitor)*60));
			time_to_sleep <-int((time_to_work + min_work_duration_for_visitor*60 + rnd(max_work_duration_for_visitor - min_work_duration_for_visitor)*60));
			objective <- "resting";
//			people_color_car 	<- rgb(31,179,90)  ;
//			people_color		<- rgb(151,26,47) ;
			type_of_agent <- "aalto_visitor";
		}
		
		// CITY_IO Initialisation
		create grid_cell from:meta_grid_file with: [interactive_id::int(read("interactive_id"))];
		
//		do update_grid_data;
//		write(count(list(aalto_staff) , (each.could_not_find_parking = false)));
		
//		do creat_headings_for_csv;


	}

//	reflex updateGraph when: (drawInteraction = true) {
//		interaction_graph <- graph<aalto_staff, aalto_staff>(aalto_staff as_distance_graph (distance));
//	}
	
	//////////////////////////////////////////
	//
	// 		DATA RECODRDING SECTION:
	//
	//////////////////////////////////////////
	
//	int day_counter <- 1;
//	string pressure_csv_path <- "../results/";
//	string capacity_csv_path<- "../results/";
//	
//	action record_parking_attribute{
//		pressure_record <- pressure_record + current_time;
//		capacity_record <- capacity_record + current_time;
//				
//		loop a from: 0 to: length(list_of_parkings)-1	 { 
//			recording_parking_sample <-list_of_parkings[a];
//			pressure_record <- pressure_record + list_of_parkings[a].pressure *multiplication_factor + "," ;
//			capacity_record <- capacity_record + list_of_parkings[a].vacancy *multiplication_factor + "," ;
//		}	
//		pressure_record <- pressure_record + char(10);
//		capacity_record <- capacity_record + char(10);
//	}
//	
//	action creat_headings_for_csv {
//		loop b from: 0 to: length(list_of_parkings)-1	 { 
//			pressure_record <- pressure_record + list_of_parkings[b].ID + "," ;
//			capacity_record <- capacity_record + list_of_parkings[b].ID + "," ;
//		}		
//		pressure_record <- pressure_record + char(10);
//		capacity_record <- capacity_record + char(10);
//	}
//
//	reflex save_the_csv when: current_time = (first_hour_of_day *60){
//
////		total_pressure<-0;
//		save string(pressure_record) to: pressure_csv_path + string(#now, 'yyyyMMdd- H-mm - ') + "pressure" + day_counter + ".csv"  type:text ;
//		save string(capacity_record) to: pressure_csv_path + string(#now, 'yyyyMMdd- H-mm - ') + "capacity" + day_counter + ".csv"  type:text ;
//		day_counter <- day_counter +1;
//		loop t from: 0 to: length(list_of_parkings)-1	 { 
//			parking[t].pressure <- 0;
//			
//		}
//	}
//	
//	reflex time_to_record_stuff when: current_time mod 2 = 0 {
//		do record_parking_attribute;
//	}
	
	
	////////////////////////////////////////
	//
	// 		USER INTERACTION SECTION:
	//
	////////////////////////////////////////
	
	map<string,unknown> my_input_capacity; 
	map<string,unknown> my_input_scale; 
	map<string,unknown> my_input_category;
	map my_agent_type;
	point mouse_location;
	user_command Create_parking action:create_user_parking;
	user_command Create_resi action:create_user_residential;
	user_command Create_office action:create_user_office;
	
	action record_mouse_location {
		mouse_location <- #user_location;
	}
//	action create_agents 
//	{
//		mouse_location <- #user_location;
//		write(mouse_location);
//		my_agent_type <- user_input("please enter the agent type: [1 = parking, 2 = Residential, 3 = Office]", ["type" :: 1]);
//		if my_agent_type at "type" = 1 {
//			do create_user_parking(mouse_location);
//		}
//		else if my_agent_type at "type" = 2{
//			do create_user_residential(mouse_location);
//		}
//		else if my_agent_type at "type" = 3{
//			do create_user_office(mouse_location);
//		}
//		else {
//			write("this type of agent does not exist");
//		}
//
//	}
	reflex restart_day when: current_time = (first_hour_of_day*60){
		do update_grid_data;
	}
	
	action create_user_parking {
		mouse_location <- #user_location;
//		my_input_capacity <- user_input("Please specify the parking capacity", "capacity" :: 10);
		create parking number:1 with:(location: mouse_location) {
//			capacity <- int(my_input_capacity at "capacity") ;
			capacity<- 10;
			total_capacity <-  capacity;
			//vacancy <- (int(my_input_capacity at "capacity")/int(my_input_capacity at "capacity"));
			shape <- square(20);
			list_of_parkings <- list(parking);
//			write("A parking was created with capacity of "+ char(10) + string(capacity) + char(10) + "and total capacity of " + char(10)+ string(total_capacity));
		}
	}
	
	action create_user_residential{
		mouse_location <- #user_location;
//		my_input_capacity <- user_input("Please specify the count of people living in the building", "capacity" :: 10);
//		my_input_category <- user_input("Please specify the scale ['S', 'R']", "category" :: 'S');
		create residential number:1 with:(location: mouse_location ) {
//			capacity <- int(my_input_capacity at "capacity");
			capacity<- 10;
			usage <- "R";
//			category<-string(my_input_category at 'category');
			category<-'R';
			shape <- square(20);
			color <- rgb(255,255,0,50);
//			write("A building was constructed and count of dwellers are: " + char(10) + string(capacity));
		}
	}
	
	action create_user_student_residential{
		mouse_location <- #user_location;
//		my_input_capacity <- user_input("Please specify the count of people living in the building", "capacity" :: 10);
		create residential number:1 with:(location: mouse_location ) {
//			capacity <- int(my_input_capacity at "capacity");
			capacity<- 10;
			usage <- "R";
			category<-'S';
			shape <- square(20);
			color <- rgb(255,255,0,50);
//			write("A building was constructed and count of dwellers are: " + char(10) + string(capacity));
		}
	}
	
	action create_user_office{
		mouse_location <- #user_location;
//		my_input_capacity <- user_input("Please specify the amount of people work at the office", "capacity" :: 10);
		create office number:1 with:(location: mouse_location) {
//			capacity <- int(my_input_capacity at "capacity");
			capacity<- 10;
			usage <- "O";
			color <- rgb(255,0,0,40);
			shape <-square(25);
//			write("A building was constructed and count of employees are: " + char(10) + string(capacity));
		}
	}

}


	////////////////////////////////////////
	//
	// 		BUILT ENVIRONMENT:
	


species building schedules: [] {
	string usage;
	string scale;
	string category;
	float nbFloors <- 1.0; // 1 by default if no value is set.
	int depth;
	float area;
	float perimeter;
	}
	
species grid_cell {
	int interactive_id;
	aspect base {
		draw shape border: rgb(250,250,250,100) empty: true;
	}
}

species Aalto_buildings schedules:[] {
	bool interactive<-false;
	string usage;
	int interactive_id<-nil;
	string scale;
	string category;
	rgb color <- rgb(150,150,150,30);
	aspect base {
		draw shape color: color  depth:  (total_capacity / 5);
	}
	int capacity;
	int total_capacity;
	float weight;
}

species office parent:Aalto_buildings schedules:[] {
	action accept_people {
		capacity <- capacity -1;
	}
	
	action remove_people {
		capacity <- capacity + 1;		
	}
}

species residential parent:Aalto_buildings schedules:[] {
	action accept_people {
		capacity <- capacity -1;
	}
	
	action remove_people {
		capacity <- capacity + 1;		
	}
}

// Gateways are representing the people who are NOT living in campus

species gateways parent:residential schedules:[] {
	aspect base {
		draw circle(20) color: #blue;
	}
}

species parking {
	int interactive_id<-nil;
	bool interactive<-false;
	float weight;
	int ID;
	int total_capacity;
	int capacity<-total_capacity;
	int excess_time <- 600;
	int pressure <- 0 ;
	//TODO: This should be fixed, for now it prevents division by zero
	float vacancy <- (capacity/(total_capacity)) update: (capacity/(total_capacity) );
	aspect Envelope {
		draw shape color: rgb(200 , 200 * vacancy, 200 * vacancy) ;
	}
	aspect pressure {
		draw circle(5) depth:pressure * multiplication_factor color: #orange;
	}
	
	reflex reset_the_pressure when: current_time = (first_hour_of_day*60) {
		pressure <- 0 ;
	}
}

species car_road schedules:[]{
	aspect base{
		draw shape color: rgb(50,50,50) width:2;
	}
}

	////////////////////////////////////////
	//
	// 		PEOPLE:


species aalto_people skills: [moving] {
	
	office working_place;
	residential living_place;
	
	bool driving_car<-true;
	bool mode_of_transportation_is_car <- false;
	bool could_not_find_parking <- false;
	bool commuter<-false;
	
	int time_to_work;
	int time_to_sleep;
	
	string type_of_agent;
	list<parking> list_of_available_parking;

	point the_target_parking;
	parking chosen_parking;
	string objective;
	
	point the_target <- nil;
	point living_place_location;
	
	rgb people_color_car ;
	rgb people_color	;
	
	map<string, int> distances_travelled<-['drive'::0, 'pt'::0,'cycle'::0,'walk'::0];
//	int distance_walked<-0;
//	int distance_driven<-0;
	
	float commute_distance<-0.0;
	string mode_choice;
	
	// ----- ACTIONS
	
	action create_list_of_parkings{
		list_of_available_parking <- sort_by(parking where (distance_to(each.location, working_place) < max_walking_distance  ),distance_to(each.location, working_place));
	}
	
	action choose_mode{
		driving_car <- false;
		using topology(car_road_graph){
		     commute_distance <- distance_to (living_place_location,working_place);
		}
		float ext_dist<-0;
		if (commuter=true){
			ext_dist<-1400*exp(gauss(2.17, 1.16));
			// sample from lognormal distribution calibrated with survey data (straight line distance)
			// multiply by 1.4 for approx network distance
			commute_distance<-commute_distance+ext_dist;
		}
		list mode_choice_freq;
		if (commute_distance<1000){
			mode_choice_freq<-[5, 1, 21, 79];
		}
		else if (commute_distance<3000){
			mode_choice_freq<-[21, 15, 48, 20];
		}
		else if (commute_distance<5000){
			mode_choice_freq<-[14, 16, 14, 1];
		}
		else if (commute_distance<7000){
			mode_choice_freq<-[10, 13, 6, 0];
		}
		else if (commute_distance<10000){
			mode_choice_freq<-[11, 15, 6, 0];
		}
		else if (commute_distance<15000){
			mode_choice_freq<-[14, 18, 4, 0];
		}
		else if (commute_distance<25000){
			mode_choice_freq<-[13, 14, 1, 0];
		}
		else if (commute_distance<50000){
			mode_choice_freq<-[10, 6, 0, 0];
		}
		else {
			mode_choice_freq<-[1, 1, 0, 0];
		}
		mode_choice<-sample(['drive', 'pt', 'cycle', 'walk'],1,false,mode_choice_freq)[0];
		if (mode_choice='drive'){
			mode_of_transportation_is_car <- true ;
		}
		else {
			mode_of_transportation_is_car <- false ;
		}
		distances_travelled[mode_choice]<-distances_travelled[mode_choice]+ext_dist;
	}
	
	action find_living_place {
		if ((sum((residential where (each.category = people_to_housing_types[type_of_agent])) collect each.capacity)!= 0 )){
			living_place <- one_of(shuffle((residential where (each.category = people_to_housing_types[type_of_agent])) where (each.capacity > 0)));
				ask living_place {
					do accept_people;
			}
//			mode_of_transportation_is_car <- false ;
			commuter<-false;
		}
		else {
			living_place <- one_of(shuffle(gateways));
//			mode_of_transportation_is_car <- true;
			commuter<-true;
		}
	}
	
	
	action park_the_car(parking target_parking) {
		target_parking.capacity <- target_parking.capacity -1;
	}
	
	action take_the_car(parking target_parking) {
		target_parking.capacity <- target_parking.capacity +1;
	}
	
	
	action choose_working_place {
		working_place <- one_of(shuffle(office where (each.capacity > 0)));
		ask working_place{
			do accept_people;
		}
	}
	
	action Choose_parking {
		do create_list_of_parkings;
		chosen_parking <- one_of(list_of_available_parking where (
											(each.capacity 		> 0) and 
											(each.excess_time 	> (time_to_work - time_to_sleep) 
											))
		);
		the_target_parking <- any_location_in(chosen_parking);		
	}
	
	// ----- REFLEXES 	
	
	reflex reset_day when: current_time = (first_hour_of_day*60) {
//		distance_driven <- 0 ;
//		distance_walked <- 0 ;
		distances_travelled<-['drive'::0, 'pt'::0,'cycle'::0,'walk'::0];
		if living_place != nil {
			ask living_place{
				do remove_people;
			}
		}
		do find_living_place;
		living_place_location <- any_location_in(living_place);
		location <- living_place_location;
	}
	reflex time_to_go_to_work when: current_time > time_to_work and current_time < time_to_sleep and objective = "resting" {
		could_not_find_parking <- false;		
		do choose_working_place;
		do choose_mode;
		
		if (mode_of_transportation_is_car = true) {
			do Choose_parking;
		}	

		the_target <- any_location_in(working_place);
		objective <- "working";
		
	}
	
	reflex time_to_go_home when:  current_time > time_to_sleep and objective = "working" {
		objective <- "resting";
		ask working_place {
			do remove_people;
		}
		the_target <- any_location_in(living_place);
	}
	
	reflex change_mode_of_transportation when: mode_of_transportation_is_car = true and (location = the_target_parking or location = living_place_location) {
// TODO needs re-definition. 
		if location = the_target_parking {
			if chosen_parking.capacity > 0 and objective = "working"{
				driving_car <- false;
				do park_the_car(chosen_parking);
			}
			else if objective = "resting" and driving_car = false{
				driving_car <- true;
				do take_the_car(chosen_parking);
	
			}
			else if (list_of_available_parking collect each.capacity) != 0 {
//				write('Arrived at full parking');
				chosen_parking.pressure <- chosen_parking.pressure  + 1;
				do Choose_parking;
			}
			else{
				could_not_find_parking <- true;
				the_target <- any_location_in(living_place);
				objective <- "resting";
				chosen_parking <- nil;
//				write('No parking available');
			}
		
		}
		else {
			if objective = "working" {
				driving_car <- true;
			}
			else {
				driving_car <- false;
				the_target <- nil;
			}
		}

	}
	reflex move when: the_target != nil {
		
		// move the agent
		if (driving_car = true){
			
			if (objective = "working"){
				do goto target: the_target_parking on: car_road_graph  speed: mode_speed_map[mode_choice];
			}
			else{
				do goto target: the_target on: car_road_graph speed: mode_speed_map[mode_choice];
			}
		}
		else {
			
			if (objective = "working"  ){
				do goto target: the_target on: car_road_graph speed: mode_speed_map[mode_choice];
			}
			else {
				if (mode_of_transportation_is_car = true){
					do goto target: the_target_parking on: car_road_graph speed: mode_speed_map[mode_choice];
				}
				else {
					do goto target: the_target on: car_road_graph speed: mode_speed_map[mode_choice];
				}
			}
		}
		
		// then update distances travelled
		if (mode_of_transportation_is_car = true){
			if (driving_car=true){
				// is a driver and is driving right now
				distances_travelled['drive']<-distances_travelled['drive']+real_speed*step;
			}
			else {
				// is a driver but is walking now
				distances_travelled['walk']<-distances_travelled['walk']+real_speed*step;
			}
		}
		else {
			// not a driver
			distances_travelled[mode_choice]<-distances_travelled[mode_choice]+real_speed*step;
		}
		
		// conclude trip?
      	if the_target = location {
        	the_target <- nil ;
		}
	}
	
	
	
	aspect base {
		if driving_car = true {
			draw square(10) color: mode_color_map[mode_choice];
		} else{
			draw circle(4) color: mode_color_map[mode_choice];
		}
		
	}
	aspect show_person_type {
		if driving_car = true {
			draw square(10) color: people_color_map[type_of_agent];
		} else{
			draw circle(4) color: people_color_map[type_of_agent];
		}
		
	}
}

species aalto_staff parent: aalto_people {
	aspect interaction {
		ask (aalto_student where (each.driving_car = false)) at_distance(distance) {
		    draw polyline([self.location,myself.location]) color:rgb(255,255,0, 125);
		}
	}
}

species aalto_student parent: aalto_people {
	
}

species aalto_visitor parent: aalto_people {
	
}






// ----------------- EXPREIMENTS -----------------
experiment parking_pressure type: gui {
	float minimum_cycle_duration <- 0.2;
	output {

		display charts {
//			chart "parking occupied (%)" size: {0.5 , 0.5} type: series{
//				datalist list(parking)
//				value: list((parking collect ((1-each.vacancy)*100)))
//				marker: false
//				style: spline;
//			} 
			chart "total parking vacancy" size: {0.5 , 0.5}  position: {0,0.5}type: series{
				data "Total Parking Vacancy (%)"
				value: mean(list(parking) collect each.vacancy)
				marker: false
				style: spline;
				
			} 

			chart "Total Parking presure"	size: {0.5 , 0.5}	position: {0.5,0.5} type: series{
				data "Total Parking Pressure"
				value: sum(list(parking) collect each.pressure)
//				value: total_pressure
				marker: false
				style: line;
			}	
			chart "Parking Status" size: {0.5 , 0.5}  type: pie{
				data "Vacant Parkings" value: count(list(parking), each.vacancy > 0);
				data "Full Parkings" value: count(list(parking), each.vacancy = 0);
			}
		
		}
		
		// This block was for generating pie charts. Because of changes in user groups it is no longer active.
		// TODO: Fix these charts
		
//		display pie_charts {
//			chart "Staff found suitable parking (%)" size:{0.3 , 0.2} position: {0,0.2} type:pie{
//				data "Parking found"value: list(aalto_people) count (each.chosen_parking != nil) color:#chartreuse;
//				data "Parking Not specified" value: list(aalto_people) count (each.chosen_parking = nil) color:#coral;
//				data "Parking Not found" value: list(aalto_people) count (each.could_not_find_parking = true) color:#grey;
//			}
//			chart "Students found suitable parking (%)" size:{0.3 , 0.2} position: {0,0.4} type:pie{
//				data "Parking found"value: list(aalto_people) count (each.chosen_parking != nil) color:#chartreuse;
//				data "Parking Not specified" value: list(aalto_people) count (each.chosen_parking = nil) color:#coral;
//				data "Parking Not found" value: list(aalto_people) count (each.could_not_find_parking = true) color:#grey;
//			}
//			chart "Visitors found suitable parking (%)" size:{0.3 , 0.2} position: {0,0.6} type:pie{
//				data "Parking found"value: list(aalto_people) count (each.chosen_parking != nil) color:#chartreuse;
//				data "Parking Not specified" value: list(aalto_people) count (each.chosen_parking = nil) color:#coral;
//				data "Parking Not found" value: list(aalto_people) count (each.could_not_find_parking = true) color:#grey;
//			}
//			
//			chart "Count of parkings with capacity" size:{0.3 , 0.5} position: {0.3,0} type:pie{
//				data "Parkings with remaining capacity"value: list(parking) count (each.vacancy != 0) color:#chartreuse;
//				data "Parkings with Full capacity"value: list(parking) count (each.vacancy = 0) color:#coral;
//			}
//			chart "total remaining capacity" size:{0.3 , 0.5} position: {0.6,0} type:pie{
//				data "vacant (%)"value: mean(list(parking) collect each.vacancy) color:#chartreuse;
//				data "Full (%)"value: 1 - mean(list(parking) collect each.vacancy) color:#coral;
//			}
//			chart "found suitable parking (%)" size:{1 , 0.5} position: {0,0.5} type:series{
//				data "Parking found"value: list(aalto_people where (each.mode_of_transportation_is_car = true)) count (each.chosen_parking != nil and each.could_not_find_parking != true) 
//				color:#chartreuse
//				marker: false;
//			}
//		}

		// 2D Display has actions for creating new agents by user interaction
		// 3D display caused inaccuracies for user interaction.
		
		display person_type_interface type:java2D background: #black{
			species grid_cell aspect: base;
			species car_road aspect: base ;
			species parking aspect: Envelope ;
			species residential aspect:base;
			species gateways aspect:base;
			species aalto_staff aspect:show_person_type;
			species aalto_staff aspect:interaction;
			species aalto_student aspect:show_person_type;
			species aalto_visitor aspect:show_person_type;
//			species office aspect:base;
			
			
			overlay position: { 3,3 } size: { 150 #px, 80 #px } background: # gray transparency: 0.8 border: # black
			{	
  				draw "Students " at: { 20#px, 20#px } color: people_color_map['aalto_student'] font: font("Helvetica", 20, #bold ) perspective:false;
  				draw "Staff " at: { 20#px, 40#px } color: people_color_map['aalto_staff'] font: font("Helvetica", 20, #bold ) perspective:false;
  				draw "Visitors " at: { 20#px, 60#px } color: people_color_map['aalto_visitor'] font: font("Helvetica", 20, #bold ) perspective:false;
            }
		// key for character C initiates the create action.
			
//			event 'c' action: create_agents;
			event 'p' action: create_user_parking;
			event 'r' action: create_user_residential;
			event 's' action: create_user_student_residential;
			event mouse_up action: record_mouse_location;
		}

		
//		display Map_3D type:opengl background: #black{
//			species car_road aspect: base ;
//			species parking aspect: Envelope ;
//			species parking aspect: pressure;
//			species office aspect:base;
//			species residential aspect:base;
//			species aalto_staff aspect:base;
//			species aalto_student aspect:base;
//			species aalto_visitor aspect:base;
//			species gateways aspect:base;
//		}
		display mode_3d_interface type:opengl background: #black camera_pos: {1400,1200,3000} camera_look_pos: {1400,1200,0}{
			species grid_cell aspect: base;
			species car_road aspect: base ;
			species parking aspect: Envelope ;
			species parking aspect: pressure;
//			species office aspect:base;
			species residential aspect:base;
			species aalto_staff aspect:base;
			species aalto_student aspect:base;
			species aalto_visitor aspect:base;
			species gateways aspect:base;
			
			overlay position: { 3,3 } size: { 150 #px, 100 #px } background: # gray transparency: 0.8 border: # black
			{	
  				draw "Drive " at: { 20#px, 20#px } color: mode_color_map['drive'] font: font("Helvetica", 20, #bold ) perspective:false;
  				draw "Cycle " at: { 20#px, 40#px } color: mode_color_map['cycle'] font: font("Helvetica", 20, #bold ) perspective:false;
  				draw "Walk " at: { 20#px, 60#px } color: mode_color_map['walk'] font: font("Helvetica", 20, #bold ) perspective:false;
  				draw "PT " at: { 20#px, 80#px } color: mode_color_map['py'] font: font("Helvetica", 20, #bold ) perspective:false;
            }
			
			chart " " background:#black  type: pie style: ring size: {0.5,0.5} position: {world.shape.width*1.1,0} color: #white 
			tick_font: 'Helvetica' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Helvetica' label_font_size: 1 label_font_style: 'bold'
			{

				  data 'Commuters' value: length(aalto_student where (each.commuter = true))+length(aalto_staff where (each.commuter = true)) color:#red;
				  data 'Live-Work' value: length(aalto_student where (each.commuter = false))+length(aalto_staff where (each.commuter = false)) color:#green;
				
			}
			chart " " background:#black  type: pie style: ring size: {0.5,0.5} position: {world.shape.width*1.1,world.shape.height*0.5} color: #white 
			tick_font: 'Helvetica' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Helvetica' label_font_size: 1 label_font_style: 'bold'
			{

				  data 'Km driven' value: (sum(aalto_student collect each.distances_travelled['drive'])+
				  							sum(aalto_staff collect each.distances_travelled['drive'])+
				  							sum(aalto_visitor collect each.distances_travelled['drive'])
				  							) color:#gamaorange;
				  data 'Km walked' value: (sum(aalto_student collect each.distances_travelled['walk'])+
				  							sum(aalto_staff collect each.distances_travelled['walk'])+
				  							sum(aalto_visitor collect each.distances_travelled['walk'])
				  							) color:#green;
				  data 'Km cycled' value: (sum(aalto_student collect each.distances_travelled['cycle'])+
				  							sum(aalto_staff collect each.distances_travelled['cycle'])+
				  							sum(aalto_visitor collect each.distances_travelled['cycle'])
				  							) color:#blue;
				  data 'Km PT' value: (sum(aalto_student collect each.distances_travelled['pt'])+
				  							sum(aalto_staff collect each.distances_travelled['pt'])+
				  							sum(aalto_visitor collect each.distances_travelled['pt'])
				  							) color:#yellow;
				
			}

//			graphics "interaction_graph" {
//				if (interaction_graph != nil) {
//					loop eg over: interaction_graph.edges {
//						aalto_staff src <- interaction_graph source_of eg;
//						aalto_staff target <- interaction_graph target_of eg;
//						geometry edge_geom <- geometry(eg);
//						draw line(edge_geom.points) color: rgb(0, 125, 0, 75);
//					}
//
//				}
//				
//			}
		}
	}
	
}

