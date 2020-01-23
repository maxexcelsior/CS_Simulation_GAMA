/***
* Name: segregplanetary
* Author: 
* Description: 
* Tags: Tag1, Tag2, TagN
* en que uds esta distance en evaluate_main_trip¿?¿? luego al normalizar no pasa nada, pero nos interesa compararlo con renta por lo que valor abs 
* en que uds esta el speed¿?¿? la medida de distancia/m
* no se si tiene mucho sentido sumar commuting cost respecto a precio ref de $1500 y las rentas normalizadas
* ya tengo para cada persona a cuanto tiempo y distancia le queda cada planetary_city. De alguna manera ponderarlo y compararlo con el building de move
***/

model segregplanetary

global{
	int totalSupportedPeople<-0;
	map<string,int> possible_unitSizes<-["S"::1,"M"::2,"L"::3];
	float happyUnitSizePeople;
	map<string,float> happyUnitSize_perProfile;
	float happyNeighbourhoodPeople;
	map<string,float> happyNeighbourhood_perProfile;
	float meanRentPeople;
	map<string,float> meanRent_perProfile;
	list<point> busStop_locations <- [{416.065842541361,872.4406645256535},{295.6297241536236,1539.974425847902},{117.57324879127151,1366.4780559606388},{844.7128639433781,1152.1258495633292},{1223.250124982041,794.9240374419919},{528.8729859709387,115.20351949292453},{303.3080137033162,61.469988319234204}];
	int reference_rent <- 1500; //se calculará el commuting cost en porcentaje respecto a este precio de referencia. Cuando tenga precios, será el menor de todos.
	int days_per_month <- 20; //dias laborales por mes
	list<planetary_city> list_planetary_cities <- [];
	
	bool weatherImpact<-false;
	float weather_of_day min: 0.0 max: 1.0;	
	
	list<float> dist_weights;
	float meanRentnorm<-0.0;
	//int supported_people<-5;	
	float meanDiversityGlobal<-0.0;
	int movingPeople<-0;
	float meanTimeToMainActivity;
	map<string,float> meanTimeToMainActivity_perProfile;
	float meanDistanceToMainActivity;
	map<string,float> meanDistanceToMainActivity_perProfile;
	map<string,float> people_per_Mobility_now; //proportion
	list<point> FinalLocation<-[];
	list<string> typeFinalLocation<-[];
	list<float> meanDiversityRecord<-[];
	list<int> peopleMovingRecord<-[];
	list<int> happyUnitSizePeopleRecord <- [];
	list<int> happyNeighbourhoodPeopleRecord <- [];
	list<float> meanTimeRecord<-[];
	list<float> meanDistanceRecord <- [];
	list<float> meanCommutingCostRecord <- [];
	list<map> proportionMobilityRecord;
	list<float> meanRentRecord <- [];
	map<string,int> density_map<-["S"::15,"M"::55, "L"::89];
	map<string,string> main_activity_map;
	map<string, float> proportion_per_type;
	map<string, float> proba_bike_per_type;
	map<string, float> proba_car_per_type;	
	list<list<float>> weather_of_month;
	map<string,list<float>> charact_per_mobility;
	map<string,rgb> color_per_mobility;
	map<string,float> width_per_mobility;
	map<string,float> speed_per_mobility;
	map<string,float> weather_coeff_per_mobility;
	map<string,graph> graph_per_mobility;
	map<string,map<string,list<float>>> weights_map <- map([]);
	map<string,float> time_importance_per_type;
	map<road,float> congestion_map;  
	list<string> allPossibleMobilityModes<-["walking","car","bike","bus"];
	map<string,int> nPeople_per_mobility;
	map<string,map<string,float>> propPeople_per_mobility_type <- map([]);
	map<string,int> nPeople_perProfile;
	float meanCommutingCostGlobal;
	map<string,float> meanCommutingCost_perProfile;
	
	
	int nb_people<-1500;
	list<string> type_people;
	//los operarios habra que ponerlos en algun amenity no en oficina
	map<string,rgb> color_per_type;	
	map<string,float> priceImp_list;
	map<string,float> divacc_list;
	map<string,string> unitSize_list;
	map<string,float> unitSizeWeight_list;
	map<string,string> pattern_list;
	map<string,float> patternWeight_list;
	
	file weight_distances_file<-file("./../includes/Game_IT/WeightDistances.csv");
	file criteria_home_file <- file("./../includes/Game_IT/CriteriaHome.csv");
	string case_study<-"volpe";
	string cityGISFolder<-"./../includes/City/"+case_study;
	file<geometry>buildings_shapefile<-file<geometry>(cityGISFolder+"/Buildings.shp");
	file<geometry> roads_shapefile<-file<geometry>(cityGISFolder+"/Roads.shp");
	file activity_file <- file("./../includes/Game_IT/ActivityPerProfile.csv");
	file mode_file <- file("./../includes/Game_IT/Modes.csv");
	file criteria_file <- file("./../includes/Game_IT/CriteriaFile.csv");
	file profile_file <- file("./../includes/Game_IT/Profiles.csv");
	file weather_coeff <- file("../includes/Game_IT/weather_coeff_per_month.csv");
	file planetary_city_doc <- file("../includes/Game_IT/PlanetaryCities.csv");
	geometry shape<-envelope(roads_shapefile);
	
	init{
		do read_priceWeights;
		do read_criteriaHome;
		do createCity;
		do createBuildings;
		do createRoads;
		do createBusStop;
		do createTStop;
		do calculateAbsRent;
		do calculateNormRent;
		do criteria_file_import;		
		do characteristic_file_import;
		do profils_data_import;
		do activityDataImport;
		do calc_time_criteria_per_type;
		do import_weather_data;
		if (weatherImpact=true){
			do calculate_weather;
		}
		do compute_graph;
		do countTotalSupportedPeople;
		do createPopulation;
		do countPopulation;
		do initcalculateDiversityBuilding;
		do countRent;
		do countHappyPeople;
		do countMobility;		
	}
	
	action read_priceWeights{
		matrix dist_weights_matrix <- matrix(weight_distances_file);
		loop i from:0 to: dist_weights_matrix.rows-1{
			dist_weights << dist_weights_matrix[1,i];
		}
	}
	
	action read_criteriaHome{
		matrix criteriaHome_matrix <- matrix(criteria_home_file);
		loop i from: 0 to: criteriaHome_matrix.rows-1{
			type_people << criteriaHome_matrix[0,i];
			priceImp_list << (type_people[i]::criteriaHome_matrix[1,i]);
			divacc_list << (type_people[i]::criteriaHome_matrix[2,i]);
			unitSize_list << (type_people[i]::criteriaHome_matrix[3,i]);
			unitSizeWeight_list << (type_people[i]::criteriaHome_matrix[4,i]);
			pattern_list << (type_people[i]::criteriaHome_matrix[5,i]);
			patternWeight_list << (type_people[i]::criteriaHome_matrix[6,i]);		
			 
		}
	}
	
	action createCity{
		create city number:1{
			minRent <- 0.0;
			maxRent <- 100.0;	
			name <- "ppal";
		}
		
		//create planetary cities
		do importPlanetaryCities;
	}
	
	action importPlanetaryCities{
		matrix planetary_matrix <- matrix(planetary_city_doc);
		loop i from: 0 to: planetary_matrix.rows - 1{
			create planetary_city{
				name <- planetary_matrix[0,i];
				dist <- planetary_matrix[1,i];
				has_bus <- planetary_matrix[2,i];
				has_T <- planetary_matrix[3,i];
				meanRent <- planetary_matrix[4,i];
				meanRent <- meanRent + 1; //para que no estén en negativo
				location_x <- planetary_matrix[5,i];
				location_y <- planetary_matrix[6,i];
				location <- {location_x,location_y};
				possible_transport <- ["car"];
				if (has_bus = true){
					possible_transport << "bus";
				}
				if (has_T = true){
					possible_transport << "T"; 
				}
				list_planetary_cities << self;
				create sat_building{
					myCity <- list_planetary_cities[i];
					rentPriceNorm <- list_planetary_cities[i].meanRent;
					diversityNorm <- 0.5;
					neighbourhood <- list_planetary_cities[i].name;
					location <- list_planetary_cities[i].location;
					satellite <- true;
					list_planetary_cities[i].planetary_building <- self;
				}
				planetary_building <- list_planetary_cities[i].planetary_building;
			}			
		}
		//write list_planetary_cities;
	}
	
	action createBuildings{
		create building from: buildings_shapefile with:[usage::string(read("Usage")),scale::string(read("Scale")),category::string(read("Category")), FAR::float(read("FAR")), max_height::float(read("Max_Height")), type::string(read("TYPE")), neighbourhood::string(read("NAME"))] {
			myCity <- one_of(city where(each.name = "ppal"));
			area<-shape.area;
			perimeter<- shape.perimeter;	
			nbFloors<-int(max_height/10);
			if (density_map[scale]!=0 and usage="R"){
				supported_people<-int(area/density_map[scale])*nbFloors;	
			}
			else{
				supported_people<-0;
			}
			vacant<-supported_people;
			satellite <- false;	
		}
	}
	
	
	action createRoads{
		create road from: roads_shapefile {
			mobility_allowed <-["walking","bike","car","bus"];
			capacity <- shape.perimeter / 10.0;
			congestion_map [self] <- shape.perimeter;
		}
	}
	
	action createBusStop{
		int cont<- 0;
		create bus_stop number:length(busStop_locations){
			location <- busStop_locations[cont];
			cont <- cont + 1;
		}
	}
	
	action createTStop{
		create T_stop number:1{
			//located_building <- building where (each.name = "building261");
			//location<-any_location_in(located_building);
			location <- {956.800386569075,1163.5265618864044,0.0};
		}
	}
	
	action calculateAbsRent{
		ask building where(each.usage="R"){
			distances<-calculateDistances();
			rentPriceabs<-calculateRent();
		}
	}
	
	action calculateNormRent{
		ask building where(each.usage="R"){
			rentPriceNorm<-normalise_rent();
			do changeColorPrice;
		}
	}
	
	action criteria_file_import {
		matrix criteria_matrix <- matrix (criteria_file);
		int nbCriteria <- criteria_matrix[1,0] as int;
		int nbTO <- criteria_matrix[1,1] as int ;
		int lignCategory <- 2;
		int lignCriteria <- 3;
		
		loop i from: 5 to:  criteria_matrix.rows - 1 {
			string people_type <- criteria_matrix[0,i];
			int index <- 1;
			map<string, list<float>> m_temp <- map([]);
			if(people_type != "") {
				list<float> l <- [];
				loop times: nbTO {
					list<float> l2 <- [];
					loop times: nbCriteria {
						add float(criteria_matrix[index,i]) to: l2;
						index <- index + 1;
					}
					string cat_name <-  criteria_matrix[index-nbTO,lignCategory];
					loop cat over: cat_name split_with "|" {
						add l2 at: cat to: m_temp;
					}
				}
				add m_temp at: people_type to: weights_map;
			}
		}
	}
	

	
	action calc_time_criteria_per_type{
		map<string,list<float>> crits;
		list<float> crits_main_activity <- [];
		string main_activity_code;
		loop type_i over:type_people {
			crits<-weights_map[type_i];
			if (main_activity_map[type_i] in ["OS","OM","OL"]){
				main_activity_code<-first(main_activity_map[type_i]);
			}
			else{
				main_activity_code <- main_activity_map[type_i];
			}
			crits_main_activity <- crits[main_activity_code];
			time_importance_per_type[type_i]<-crits_main_activity[1];
		}
	}
	
	
	action characteristic_file_import{
		matrix mode_matrix<- matrix(mode_file);
		loop i from:0 to: mode_matrix.rows - 1 {
			string mobility_type <- mode_matrix[0,i];
			if(mobility_type!=""){
				list<float> vals<- [];
				loop j from: 1 to: mode_matrix.columns - 2 {
					vals<<float(mode_matrix[j,i]);
				}
				charact_per_mobility[mobility_type]<-vals;
				color_per_mobility[mobility_type]<- rgb(mode_matrix[7,i]);
				width_per_mobility[mobility_type]<- float(mode_matrix[8,i]);
				speed_per_mobility[mobility_type]<- float(mode_matrix[9,i]);
				weather_coeff_per_mobility[mobility_type]<- float(mode_matrix[10,i]);
			}
		}		
	}
	
	action profils_data_import{
		matrix profile_matrix<- matrix(profile_file);
		loop i from:0 to: profile_matrix.rows-1{
			string profil_type<-profile_matrix[0,i];
			if(profil_type!=""){
				color_per_type[profil_type] <- rgb(profile_matrix[1,i]);
				proba_car_per_type[profil_type]<-float(profile_matrix[2,i]);
				proba_bike_per_type[profil_type]<-float(profile_matrix[3,i]);
				proportion_per_type[profil_type]<-float(profile_matrix[4,i]);
			}
		}	
	}
	
	action import_weather_data{
		matrix weather_matrix<-matrix(weather_coeff);
		loop i from:0 to: weather_matrix.rows -1 {
			weather_of_month<<[float(weather_matrix[1,i]),float(weather_matrix[2,i])];
		}
	}
	
	action calculate_weather{
		list<float> weather_m<-weather_of_month[current_date.month-1];
		weather_of_day<- gauss(weather_m[0],weather_m[1]);
	}
	
	action compute_graph{
		loop mobility_mode over: color_per_mobility.keys{
			graph_per_mobility[mobility_mode]<- as_edge_graph (road where (mobility_mode in each.mobility_allowed)) use_cache false;
		}
	}
	
	action createPopulation{
		create people number:nb_people{
			type<-proportion_per_type.keys[rnd_choice(proportion_per_type.values)];
			priceImportance<-priceImp_list[type];
			living_place<-one_of(building where (each.usage="R" and each.vacant>0));
			living_place.vacant<-living_place.vacant-1;		
			payingRent <- living_place.rentPriceNorm;	
			priorHouse<<living_place;
			exploredHouse<<living_place;
			location<-any_location_in(living_place);
			color<-color_per_type[type];
			actualUnitSize<-living_place.scale;
			actualNeighbourhood <- living_place.neighbourhood;
			unitSizeWeight<-calculate_unitSizeWeight(actualUnitSize);
			actualPatternWeight <- calculate_patternWeight(actualNeighbourhood);
			if (living_place.scale=unitSize_list[type]){
				happyUnitSize<-1;
			}
			else{
				happyUnitSize<-0;
			}
			if (living_place.neighbourhood=pattern_list[type]){
				happyNeighbourhood<-1;
			}
			else{
				happyNeighbourhood<-0;
			}
			principal_activity<-main_activity_map[type];
			
			if (first(principal_activity)="O"){
				activity_place<-one_of(building where (each.category='O'));
			}
			else if(principal_activity="restaurant"){//spelling difference with respect to "R" to have different first letter
				activity_place<-one_of(building where(each.category="Restaurant"));
			}
			else if(principal_activity="A"){
				activity_place<-one_of(building where(each.category!="R" and each.category!="O"));
			}
			else{
				activity_place<-one_of(building where (each.category=principal_activity));
			}
			do calculate_possibleMobModes;
			map<string,list<float>> mobilityAndTime<- evaluate_main_trip(living_place.location,activity_place);
			list<float> extract_list <- mobilityAndTime[mobilityAndTime.keys[0]];
			time_main_activity<-extract_list[0];
			CommutingCost <- extract_list[1];
			distance_main_activity <- extract_list[2];
			mobility_mode_main_activity<-mobilityAndTime.keys[0];
			map_all_planets_transport <- calculate_planetary_transport();
			map_all_planets_features <- calculate_planetary_features();
			loop i from: 0 to: length(list_planetary_cities) - 1 {
				list extract_features_list <- map_all_planets_features[map_all_planets_features.keys[i]];
				map<string,list<float>> extract_transport_mode_map <- map_all_planets_transport[map_all_planets_transport.keys[i]];
				list<float> extract_transport_mode_list <- extract_transport_mode_map[extract_transport_mode_map.keys[0]];
				float possiblePlanetaryLivingCost <- extract_features_list[0];
				float possiblePlanetaryCommutingCost <- extract_transport_mode_list[1];
				float possiblePlanetaryDiversity <- extract_features_list[3];
				float possiblePlanetaryUnitSizeWeight <- calculate_unitSizeWeight(extract_features_list[1]);
				float possiblePlanetaryPatternWeight <- calculate_patternWeight(extract_features_list[2]);
				float possiblePlanetaryTime <- extract_transport_mode_list[0];
				list<float> possiblePlanetaryCand <- [possiblePlanetaryLivingCost + possiblePlanetaryCommutingCost, possiblePlanetaryDiversity, possiblePlanetaryUnitSizeWeight, possiblePlanetaryPatternWeight, possiblePlanetaryTime];
				map_planets_move_cand[list_planetary_cities[i]] <- possiblePlanetaryCand;
			}			
		}
	}
	
	action countPopulation{
		loop i from: 0 to: length(type_people)-1 {
			nPeople_perProfile[type_people[i]] <- people count(each.type = type_people[i]);
		}
	}
	
	action countRent{
		meanRentPeople <- mean(people collect each.living_place.rentPriceNorm);
		loop i from: 0 to: length(type_people) -1 {
			meanRent_perProfile[type_people[i]] <- mean(people where(each.type = type_people[i]) collect each.living_place.rentPriceNorm);
		}
	}
	
	action countHappyPeople{
		happyUnitSizePeople<-(people count(each.happyUnitSize=1))/nb_people;
		happyNeighbourhoodPeople <- (people count(each.happyNeighbourhood=1))/nb_people;
		
		loop i from: 0 to: length(type_people) -1 {
			happyUnitSize_perProfile[type_people[i]] <- (people where(each.type = type_people[i]) count(each.happyUnitSize = 1))/nPeople_perProfile[type_people[i]];
			happyNeighbourhood_perProfile[type_people[i]] <- (people where(each.type = type_people[i]) count(each.happyNeighbourhood =  1))/nPeople_perProfile[type_people[i]];
		}
	}
	
	action countMobility{
		propPeople_per_mobility_type <- map([]);	
		loop i from: 0 to: length(allPossibleMobilityModes)-1 {
			map<string,float> propPeople_per_mobility_indiv <- [];
			loop j from:0 to: length(type_people) - 1{
				int nPeople <- people count(each.mobility_mode_main_activity=allPossibleMobilityModes[i]);
				nPeople_per_mobility[allPossibleMobilityModes[i]] <- nPeople;
				people_per_Mobility_now[allPossibleMobilityModes[i]]<-nPeople/nb_people;
				
				//int nPeopleEach <- people where(each.type = type_people[j]) count(each.mobility_mode_main_activity = allPossibleMobilityModes[i]); 				
				int nPeopleEach <- people count(each.type = type_people[j] and each.mobility_mode_main_activity = allPossibleMobilityModes[i]);
				propPeople_per_mobility_indiv[type_people[j]] <- nPeopleEach/nPeople_perProfile[type_people[j]];
				add propPeople_per_mobility_indiv at: allPossibleMobilityModes[i] to: propPeople_per_mobility_type;				
			}
		}
		//write propPeople_per_mobility_type;

		meanTimeToMainActivity <-mean(people collect each.time_main_activity);
		meanDistanceToMainActivity <- mean(people collect each.distance_main_activity);
		loop k from:0 to: length(type_people) -1 {
			meanTimeToMainActivity_perProfile[type_people[k]] <- mean(people where(each.type = type_people[k]) collect each.time_main_activity);
			meanDistanceToMainActivity_perProfile[type_people[k]] <- mean(people where(each.type = type_people[k]) collect each.distance_main_activity);
		}
	
	}
	
	action initcalculateDiversityBuilding{
		ask building where(each.vacant!=each.supported_people){
			do calculateDiversityBuilding;
		}
		
		ask one_of(building){
			ask myCity{
				do updateCityParams;
			}			
		}
		
		ask building where(each.vacant!=each.supported_people){
			do normaliseDiversityBuilding;
		}
		
		ask one_of(building){
			ask myCity{
				do updateMeanDiver;
			}
		}
		
	}
	
	action countTotalSupportedPeople{		
		ask building where(each.usage="R"){
			totalSupportedPeople<-totalSupportedPeople+supported_people;
		}
		//nb_people<-totalSupportedPeople;
	}
	
	action activityDataImport{
		matrix activity_matrix <- matrix(activity_file);
		loop i from: 1 to: activity_matrix.rows -1{
			string people_type <- activity_matrix[0,i];
			map<string,int> activities;
			string current_activity<-"";
			list<string> act_all_day<-[];
			int posts<-0;
			list<string> list_form;
			loop j from: 1 to: activity_matrix.columns -1 {
				act_all_day<<activity_matrix[j,i];
				string act<- activity_matrix[j,i];
				if(act!=current_activity){
					activities[act]<-j;
					current_activity<-act;
					posts<-posts+1;
					list_form<<act;
				}
			}
			list<int> repetition_list<-[];
			loop j from:0 to:posts-1{
				repetition_list<<count(act_all_day,each=list_form[j]);
			}
			string main_activity<-"";
			int max_value<-0;
			loop j from:0 to: length(list_form)-1{
				if (repetition_list[j]>max_value and first(list_form[j])!="R"){
					main_activity<-list_form[j];
					max_value<-repetition_list[j];
				}	
			}
						
			if (main_activity=""){
				list<string> extended;
				list<string> list_form_larg;
				loop j from:0 to:length(list_form)-1{
					extended<- list_form[j] split_with "|";
					loop i from:0 to: length(extended)-1{
						if (first(extended[i])!="R"){
							list_form_larg<<extended[i];
						}
					}
				}
				main_activity<-one_of(list_form_larg);
			}
		
			main_activity_map[people_type]<-main_activity;
		}
	}
	
	reflex peopleMove{
		movingPeople<-0;
		ask people{
			do changeHouse;
		}
		ask one_of(building where (each.satellite = false)) {
			ask myCity{
				do updateCityParams;
			}
		}
		ask building where(each.satellite = false){
			do normaliseDiversityBuilding;
		}
		ask one_of(building where(each.satellite = false)){
			ask myCity{
				do updateMeanDiver;
			}
		}
		do countRent;
		do countHappyPeople;
		do countMobility;
	}
	
	reflex saveLocations when: cycle=199{
		ask people{
			FinalLocation<<living_place.location;
			typeFinalLocation<<type;
		}
	}
	
	/***reflex count{
		peopleMovingRecord<<movingPeople;
		meanDiversityRecord<<meanDiversityGlobal;
		happyUnitSizePeopleRecord<<happyUnitSizePeople;
		happyNeighbourhoodPeopleRecord<<happyNeighbourhoodPeople;
		meanTimeRecord<<meanTimeToMainActivity;
		meanDistanceRecord << meanDistanceToMainActivity;
		proportionMobilityRecord<<people_per_Mobility_now;
		meanRentRecord << meanRentPeople;
		meanCommutingCostRecord << meanCommutingCostGlobal;
	}***/
		
}

species people{
	string type;
	float priceImportance;
	rgb color;
	building living_place;
	list<building> priorHouse;
	list<building> exploredHouse;
	float unitSizeWeight;
	int happyUnitSize;
	string actualUnitSize;
	string actualNeighbourhood;
	float actualPatternWeight;
	int happyNeighbourhood;
	string principal_activity;
	building activity_place;
	list<string> possibleMobModes;
	string mobility_mode_main_activity; //for main_activity
	float time_main_activity;
	float distance_main_activity;
	float CommutingCost;
	float payingRent;
	map<string,map<string,list<float>>> map_all_planets_transport;
	map<string,list> map_all_planets_features; //other features apart from transportation
	map<string,list<float>> map_planets_move_cand;
	
	aspect default{
		draw circle(10) color:color;
	}
	
	map<string,map<string,list<float>>> calculate_planetary_transport {
		map<string,map<string,list<float>>> map_planet_transport;
		map<string,list<float>> each_planet_transport;
		loop i from: 0 to: length(list_planetary_cities) - 1 {
			each_planet_transport <- evaluate_main_trip(list_planetary_cities[i].location,activity_place, list_planetary_cities[i].dist);
			//write each_planet_transport;
			add each_planet_transport at:list_planetary_cities[i] to: map_planet_transport;
		}
		//write map_planet_transport;	
		return map_planet_transport;	
	}
	
	map<string,list> calculate_planetary_features{
		map<string,list> map_planet_feat;
		loop i from: 0 to: length(list_planetary_cities) - 1{
			list each_planet_feat <- [];
			each_planet_feat << list_planetary_cities[i].meanRent;
			each_planet_feat << unitSize_list[type]; //they will always be able to find their preferred unitSize
			each_planet_feat << list_planetary_cities[i].name; //they will never be fine with the neighbourhood
			each_planet_feat << list_planetary_cities[i].planetary_building.diversityNorm; //normalisedDiversity;
			map_planet_feat[list_planetary_cities[i]] <- each_planet_feat;
		} 
		return map_planet_feat;
	}
	
	map<string,list<float>> evaluate_main_trip(point origin_location,building destination, float distance_original <- nil){
		list<list> candidates;
		list<float> commuting_cost_list;
		list<float> distance_list;
		loop mode over:possibleMobModes{
			list<float> characteristic<- charact_per_mobility[mode];
			list<float> cand;	
			float distance <- 0.0;		
			if(distance_original = nil){
				using topology(graph_per_mobility[mode]){
					distance <- distance_to(origin_location,destination.location);
				}
			}
			else{
				distance <- distance_original;
			}
			cand<<characteristic[0] + characteristic[1]*distance;  //length unit meters
			commuting_cost_list << (characteristic[0] + characteristic[1]*distance/1000)/reference_rent*days_per_month*2; //price with respect to a reference rent (*2 because we have rentPrices [0,2]
			distance_list << distance;
			cand<<characteristic[2]#mn + distance/speed_per_mobility[mode];
			cand<<characteristic[4];
			
			cand<<characteristic[5]*(weatherImpact?(1.0 + weather_of_day*weather_coeff_per_mobility[mode]):1.0);
			add cand to: candidates;
		}
		//write candidates;
		//write possibleMobModes;
		//write commuting_cost_list;
		//normalisation
		list<float> max_values;
		loop i from:0 to: length(candidates[0])-1{
			max_values<<max(candidates collect abs(float(each[i])));
		}
		
		loop cand over:candidates{
			loop i from:0 to: length(cand)-1{
				if (max_values[i]!=0.0){
					cand[i] <- float(cand[i])/max_values[i];
				}
			}
		}
		
		map<string,list<float>> crits<-weights_map[type];
		list<float> vals;
		loop obj over:crits.keys{
			if(obj=destination.category or (destination.category in ["OS","OM","OL"]) and (obj = "O") or (destination.category="Restaurant" and (obj="restaurant"))){
				vals <- crits[obj];
				break;
			}
		}
		list<map> criteria_WM;
		loop i from: 0 to: length(vals)-1{
			criteria_WM<< ["name"::"crit"+i, "weight"::vals[i]];
		}
		int choice <- weighted_means_DM(candidates, criteria_WM);
		string poss_mobility_mode_main_activity;
		if (choice>=0){
			poss_mobility_mode_main_activity <- possibleMobModes[choice];
		}
		else{
			poss_mobility_mode_main_activity <- one_of(possibleMobModes);
		}
		list<float> choice_vector <- candidates[choice];
		float commuting_cost <- commuting_cost_list[choice];
		float dist <- distance_list[choice];
		float timem <- choice_vector[1];
		map<string,list<float>> mobAndTime<-(poss_mobility_mode_main_activity::[timem,commuting_cost,dist]);
		return mobAndTime;
	}
	
	action calculate_possibleMobModes{
		possibleMobModes<-["walking"];
		if (flip(proba_car_per_type[type])=true){
			possibleMobModes<<"car";
		}
		if (flip(proba_bike_per_type[type])=true){
			possibleMobModes<-"bike";
		}
		possibleMobModes<<"bus";
	}
	
	action changeHouse{
		building possibleMoveBuilding <- one_of(building where(each.usage="R" and (each.vacant>0 and (priorHouse contains each!=true and(exploredHouse contains each!=true and(each!=living_place))))));
		//building possibleMoveBuilding<-one_of(building where(each.usage="R" and each.vacant>0));
		exploredHouse<<possibleMoveBuilding;
		float possibleLivingCost<-possibleMoveBuilding.rentPriceNorm;
		float living_cost <- living_place.rentPriceNorm;
		float possibleDiversity <- possibleMoveBuilding.diversityNorm;
		string possibleUnitSize<-possibleMoveBuilding.scale;		
		float possibleUnitSizeWeight <- calculate_unitSizeWeight(possibleUnitSize);
		string possibleNeighbourhood <- possibleMoveBuilding.neighbourhood;
		float possiblePatternWeight <- calculate_patternWeight(possibleNeighbourhood);
		map<string,list<float>> possibleTimeAndMob <- evaluate_main_trip(possibleMoveBuilding.location,activity_place); //list<float> es time y commuting_cost respecto a reference_rent
		list<float> possible_extract_list <- possibleTimeAndMob[possibleTimeAndMob.keys[0]];
		float possibleTime <- possible_extract_list[0];
		float possibleCommutingCost <- possible_extract_list[1];
		string possibleMobility <- possibleTimeAndMob.keys[0];
		float possibleDistance <- possible_extract_list[2];
		list<float> crit<- [priceImp_list[type],divacc_list[type],unitSizeWeight_list[type],patternWeight_list[type],time_importance_per_type[type]];
		list<list> cands<-[[possibleLivingCost+possibleCommutingCost,possibleDiversity,possibleUnitSizeWeight,possiblePatternWeight, possibleTime],[living_cost + CommutingCost,living_place.diversityNorm,unitSizeWeight,actualPatternWeight, time_main_activity]];
		loop i from: 0 to: length(list_planetary_cities) - 1{
			list<float> possiblePlanetaryCand <- map_planets_move_cand[map_planets_move_cand.keys[i]];
			cands << possiblePlanetaryCand;
		}
		//write cands;
		list<map> criteria_WM<-[];
		loop i from:0 to: length(crit)-1{
			criteria_WM<<["name"::"crit"+i, "weight"::crit[i]];
		}		
		//write criteria_WM;
		int choice <- weighted_means_DM(cands,criteria_WM);
		
		if (choice = 0){ 
			living_place.vacant<-living_place.vacant+1;
			building noLonger_living_place <- living_place;
			possibleMoveBuilding.vacant<-possibleMoveBuilding.vacant-1;
			living_place <- possibleMoveBuilding;
			ask noLonger_living_place{
				if(satellite = false){
					do calculateDiversityBuilding;
				}
			}
			ask living_place{
				do calculateDiversityBuilding;
			}
			priorHouse<<living_place;
			location<-any_location_in(living_place);
			movingPeople<-movingPeople+1;		
			unitSizeWeight<-possibleUnitSizeWeight;
			actualUnitSize<-living_place.scale;
			actualPatternWeight <- possiblePatternWeight;
			actualNeighbourhood <- living_place.neighbourhood;
			time_main_activity <- possibleTime;
			distance_main_activity <- possibleDistance;
			mobility_mode_main_activity<-possibleMobility;
			CommutingCost <- possibleCommutingCost;
			
		}
		else if (choice != 0 and choice!= 1){
			if (living_place != list_planetary_cities[choice - 2].planetary_building){
				living_place.vacant<-living_place.vacant + 1;
				building nolonger_living_place <- living_place;
				//write nolonger_living_place;
				living_place <- list_planetary_cities[choice - 2].planetary_building;
				happyUnitSize <- 1; //suponemos que en planetary_city siempre son capaces de encontrar el unitSize que quieren
				//write living_place;
				location <- any_location_in(living_place);
				ask nolonger_living_place{
					do calculateDiversityBuilding; //que pasara si el planetario ya no es living place¿? no pasará nunca por la cond y porque nunca pasará de un planetario al otro
				}
				movingPeople <- movingPeople + 1;
				list<float> extract_cand_list <- map_planets_move_cand[map_planets_move_cand.keys[choice - 2]];
				//write extract_cand_list;
				list extract_features_list <- map_all_planets_features[map_planets_move_cand.keys[choice - 2]];
				//write extract_features_list;
				map<string,list<float>> extract_transport_map <- map_all_planets_transport[map_all_planets_transport.keys[choice - 2]];
				//write extract_transport_map;
				list extract_transport_list <- extract_transport_map[extract_transport_map.keys[0]];
				//write extract_transport_list;
				unitSizeWeight <- extract_cand_list[2];
				//write unitSizeWeight;
				actualUnitSize <- extract_features_list[1];
				//write actualUnitSize;
				actualPatternWeight <- extract_cand_list[3];
				//write actualPatternWeight;
				actualNeighbourhood <- extract_features_list[2];
				//write actualNeighbourhood;
				time_main_activity <- extract_cand_list[4];
				//write time_main_activity;
				distance_main_activity <- extract_transport_list[2];
				//write distance_main_activity;
				mobility_mode_main_activity <- extract_transport_map.keys[0];
				//write mobility_mode_main_activity;
				CommutingCost <- extract_transport_list[1];		
				//write CommutingCost;						
			}
		}
		
		if (living_place.satellite = false){
			if (living_place.scale=unitSize_list[type]){
				happyUnitSize<-1;	
			}
			else{
				happyUnitSize<-0;
			}
		}
		if(living_place.neighbourhood=pattern_list[type]){
			happyNeighbourhood <- 1;
		}
		else{
			happyNeighbourhood <- 0;
		}
	}
		
	float calculate_patternWeight(string possibleNeighbourhood){
		float possible_patternWeight;
		if(possibleNeighbourhood!=pattern_list[type]){
			possible_patternWeight<- -1.0;
		}
		else{
			possible_patternWeight<-1.0;
		}
		return possible_patternWeight;
	}
	
	float calculate_unitSizeWeight (string possibleUnitSize){
		float possibleUnitSizeWeight;
		if(possibleUnitSize!=unitSize_list[type]){
			if (possible_unitSizes[possibleUnitSize]>possible_unitSizes[unitSize_list[type]]){
				possibleUnitSizeWeight<- -1.0;	
			}
			else{
				possibleUnitSizeWeight<- -0.5;
			}
		}
		else{
			possibleUnitSizeWeight <- 1.0;
		}
		return possibleUnitSizeWeight;
	}
	
}

species city{
	float maxRent;
	float minRent;
	float meanRent;
	float maxdiver;
	float mindiver;
	float meandiver;
	string name;
	float meanCommutingCost;
	
	action updateCityParams{
		maxRent<- max(building where (each.usage="R" and each.myCity = self) collect each.rentPriceabs);
		minRent <- min(building where (each.usage="R" and each.myCity = self) collect each.rentPriceabs);
		meanRent<- mean(building where (each.usage="R" and each.myCity = self) collect each.rentPriceabs);
	
		meanRentnorm<-(meanRent-minRent)/(maxRent-minRent);
		
		maxdiver<-max(building where (each.usage = "R" and each.myCity = self) collect each.diversity);
		mindiver<-min(building where (each.usage = "R" and each.myCity = self) collect each.diversity);
		meanCommutingCost <- mean(people collect each.CommutingCost);
		meanCommutingCostGlobal <- meanCommutingCost;
		
		loop i from: 0 to: length(type_people) - 1 {
			meanCommutingCost_perProfile[type_people[i]] <- mean(people where(each.type = type_people[i]) collect each.CommutingCost);
		}
	}
	
	action updateMeanDiver{
		meandiver<-mean(building where(each.usage="R" and each.vacant!=each.supported_people and each.myCity = self) collect each.diversityNorm);
		meanDiversityGlobal<-meandiver;
	}
}

species planetary_city parent: city {
	float dist; //distance to main city
	bool has_T; //(semi-)direct T from/to Kendall
	bool has_bus;
	list<string> possible_transport;
	float location_x;
	float location_y;
	building planetary_building;
	
	aspect basic{
		draw square(20#px) color: rgb(220,220,220,125);
	}
} 

species building{
	city myCity;
	string usage;
	string scale;
	string category;
	float area;
	float perimeter;
	list<float> distances; //dist to unis, TStop, busStop, grocery...
	float rentPriceabs;
	float rentPriceNorm; //normalised
	rgb colorPrice<-#grey; //red if very expensive, green if cheaper f(dist)
	int vacant;
	float diversity<-0.0; //Shannon Weaver formula
	float diversityNorm;
	float max_height;
	int nbFloors;
	float FAR;
	string type; //building or ruins or whatever
	int supported_people; //how many people can live in this building
	string neighbourhood;	
	bool satellite;
	
	list<float> calculateDistances{
		list<float> dist_list <- [];
		list<string> interesting_buildings <- ["HS","Uni","Shopping","Cultural","Restaurant","Night","Park"];
				
		bus_stop closest_busStop<-bus_stop with_min_of(each distance_to (self));
		float dist_busStop<-distance_to(location,closest_busStop.location);
		dist_list << dist_busStop;
		
		T_stop closest_TStop<-T_stop with_min_of(each distance_to (self));
		float dist_TStop<-distance_to(location,closest_TStop.location);
		dist_list << dist_TStop;
		
		building closest_i;
		float dist_i;
		loop i from: 0 to: length(interesting_buildings) - 1 {
			if (category!=interesting_buildings[i]){
				closest_i <- building where(each.category=interesting_buildings[i]) with_min_of(each distance_to(self));
				dist_i <- distance_to(location,closest_i.location);
				dist_list << dist_i;
			}
			else{
				dist_list<<0.0;
			}
		}
		return dist_list;
	}
	
	float calculateRent{
		float rent_acum<-1;
		loop i from: 0 to:length(dist_weights)-1{
			rent_acum<-rent_acum+1/1000000*distances[i]*dist_weights[i];
		}
		float rentPrice<-rent_acum;
		return rentPrice;
	}
	
	
	float normalise_rent{
		float maxRentCity;
		float minRentCity;
		float meanRentCity;
		ask myCity{
			do updateCityParams;
			maxRentCity<-maxRent;
			minRentCity<-minRent;

			
		}
		float rentPriceNorm_gen;
		if (maxRentCity!=minRentCity){
			rentPriceNorm_gen <- (rentPriceabs-minRentCity)/(maxRentCity-minRentCity);
		}
		else{
			rentPriceNorm_gen <- 0.0;
		}
		
		rentPriceNorm_gen <- rentPriceNorm_gen + 1; //entre 1 y 2 los de Kendall. Para que Somerville etc no estén en negativo
		return rentPriceNorm_gen;
	}
	
	action calculateDiversityBuilding{
		
		diversity<-0.0;
		
		int people_livingnum<-supported_people-vacant;
		
		if (people_livingnum!=0){
			
			list<int> number_each <- [];
			list<float> proportion_each <- [];
			
			loop i from: 0 to: length(type_people)-1 {
				number_each << people count (each.living_place=self and each.type=type_people[i]);
				proportion_each << number_each[i]/people_livingnum;
			}
			loop i from:0 to:length(proportion_each)-1{
				if (proportion_each[i]!=0.0){
					diversity <- diversity + proportion_each[i]*ln(proportion_each[i]);
				}	
			}
			if (diversity!=0.0){
				diversity <- -diversity;
			}
		}
		
		else{
			diversity<-0.0;
		}
		
	}
	
	action normaliseDiversityBuilding{
		if(myCity.mindiver!=myCity.maxdiver){
			diversityNorm <- (diversity-myCity.mindiver)/(myCity.maxdiver-myCity.mindiver);
		}
		else{
			diversityNorm<-0.0;
		}
	}
	
	action changeColorPrice{
		if (usage="R"){
			float colorPriceValue<-255*(rentPriceNorm - 1);
			colorPrice<-rgb(max([0,colorPriceValue]),min([255,255-colorPriceValue]),0,125);
		}
		
		
	}
	
	aspect fPrice{
		draw shape color: colorPrice;
	}
	
	aspect default{
		draw shape color: rgb(50,50,50,125);
	}
	
}

species sat_building parent:building{
	
}

species road{
	list<string> mobility_allowed;
	float capacity;
	float max_speed <- 30 #km/#h;
	float current_concentration;
	float speed_coeff<-1.0;
	
	aspect default{
		draw shape color: #grey;
	}
}

species bus_stop{
	aspect default{
		draw square(10#px) color: #green;
	}
}

species T_stop{
	building located_building;
	aspect default{
		draw square(10#px) color:#white;
	}
}



experiment visual type:gui{
	
//parameter "Number of people" var: nb_people <- 1500 min:10 max:10000 category: "Population";
	output{
		display map type: opengl draw_env: false background: #black {
			species building aspect: fPrice;
			species road;
			species bus_stop aspect: default;
			species T_stop aspect:default;
			species people aspect: default;
			species planetary_city aspect: basic;
			
			overlay position: { 5, 5 } size: { 240 #px, 680 #px } background: # black transparency: 1.0 border: #black 
            {            	
                rgb text_color<-#white;
                float y <- 30#px;
                y <- y + 30 #px;     
                draw "Icons" at: { 40#px, y } color: text_color font: font("Helvetica", 20, #bold) perspective:false;
                y <- y + 30 #px;
                
                loop i from: 0 to: length(type_people) - 1 {
                	draw square(10#px) at: {20#px, y} color:color_per_type[type_people[i]] border: #white;
                	draw string(type_people[i]) at: {40#px, y + 4#px} color: text_color font: font("Helvetica",16,#plain) perspective: false;
                	y <- y + 25#px;
                }                    
            }
            
		}
	
			
		display MovingDiversity {			
			chart "MovingPeople" type: series background: #white position:{0,0} size:{1.0,0.5}{
				data "Moving people in myCity" value:movingPeople color:#blue;
			}
			chart "Mean diversity evolution" type: series background:#white position:{0,0.5} size:{1.0,0.5}{
				data "Mean diversity in myCity" value: meanDiversityGlobal color: #green;
			}
		}
		display HappyUnitSizeNeighbourhood{
			chart "Proportion of people happy with their UnitSize" type:series background: #white position:{0,0.0} size:{1.0,0.5}{
				data "Happy unitSize" value: happyUnitSizePeople color: #black;
				loop i from: 0 to: length(type_people) -1 {
					data type_people[i] value: happyUnitSize_perProfile[type_people[i]] color: color_per_type[type_people[i]];
				}
			}
			chart "Proportion of people happy with their Neighbourhood" type: series background:#white position: {0,0.5} size:{1.0,0.5}{
				data "Happy Neighbourhood" value: happyNeighbourhoodPeople color: #black;
				loop i from: 0 to: length(type_people) -1 {
					data type_people[i] value: happyNeighbourhood_perProfile[type_people[i]] color: color_per_type[type_people[i]];
				}
			}
					
		}
		
		display RentCommutingCosts{
			chart "Mean rent" type:series background: #white position:{0,0} size:{1.0, 0.5}{
				data "Mean normalised rent in myCity" value: meanRentPeople color: #black;
				loop i from: 0 to: length(type_people) -1 {
					data type_people[i] value: meanRent_perProfile[type_people[i]] color: color_per_type[type_people[i]];
				}
 			}
			chart "Mean CommutingCost" type:series background: #white position:{0,0.5} size:{1.0,0.5}{
				data "Mean CommutingCost" value: meanCommutingCostGlobal color: #black;
				loop i from: 0 to: length(type_people) - 1 {
					data type_people[i] value: meanCommutingCost_perProfile[type_people[i]] color: color_per_type[type_people[i]];
				}
			}
		}
		display MobilityPie{
			chart "Proportion of people per Mobility Mode" background:#black type: pie style:ring size: {0.25,0.25} position: {0.0,0.0} color: #white axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{
				loop i from: 0 to: length(people_per_Mobility_now.keys)-1	{
				  data people_per_Mobility_now.keys[i] value: people_per_Mobility_now.values[i] color:color_per_mobility[people_per_Mobility_now.keys[i]];
				}
			}
			chart "Mean time to main activity" type: series background: #white position:{0,0.25} size:{1.0,0.35}{
				data "Mean time to main activity" value:meanTimeToMainActivity color:#black;
				loop i from:0 to: length(type_people) -1 {
					data type_people[i] value: meanTimeToMainActivity_perProfile[type_people[i]] color: color_per_type[type_people[i]];
				}
			}
			chart "Mean distance to main activity" type: series background:#white position: {0,0.6} size:{1.0,0.35}{
				data "Mean distance to main activity" value:meanDistanceToMainActivity color: #black;
				loop i from: 0 to: length(type_people) - 1 {
					data type_people[i] value: meanDistanceToMainActivity_perProfile[type_people[i]] color: color_per_type[type_people[i]];
				}
			}
		}
		display MobilityChartsCarsBikes{	

			chart "Proportion of people using cars" type: series background: #white position:{0,0.0} size: {1.0,0.5}{
				data "Mean proportion of people" value: people_per_Mobility_now.values[1] color: #black;
				/***map<string,float> extract_info_mobility <- [];
				extract_info_mobility <- propPeople_per_mobility_type[allPossibleMobilityModes[1]];***/
				loop i from: 0 to:length(type_people) - 1{
					data type_people[i] value: propPeople_per_mobility_type[allPossibleMobilityModes[1]].values[i] color: color_per_type[type_people[i]];
				}
			}
			chart "Proportion of people using bikes" type: series background: #white position:{0,0.5} size: {1.0,0.5}{
				data "Mean proportion of people" value: people_per_Mobility_now.values[2] color: #black;
				/***map<string,float> extract_info_mobility <- [];
				extract_info_mobility <- propPeople_per_mobility_type[allPossibleMobilityModes[2]];***/
				loop i from: 0 to:length(type_people) - 1{
					data type_people[i] value: propPeople_per_mobility_type[allPossibleMobilityModes[2]].values[i] color: color_per_type[type_people[i]];
				}
			}	
		}
		display MobilityChartsBusWalking{
			chart "Proportion of people using bus" type: series background: #white position:{0,0.0} size: {1.0,0.5}{
				data "Mean proportion of people" value: people_per_Mobility_now.values[3] color: #black;
				/***map<string,float> extract_info_mobility <- [];
				extract_info_mobility <- propPeople_per_mobility_type[allPossibleMobilityModes[3]];***/
				loop i from: 0 to:length(type_people) - 1{
					data type_people[i] value: propPeople_per_mobility_type[allPossibleMobilityModes[3]].values[i] color: color_per_type[type_people[i]];
				}
			}
			chart "Proportion of people walking" type: series background: #white position:{0,0.5} size: {1.0,0.5}{
				data "Mean proportion of people" value: people_per_Mobility_now.values[0] color: #black;
				/***map<string,float> extract_info_mobility <- [];
				extract_info_mobility <- propPeople_per_mobility_type[allPossibleMobilityModes[0]];***/
				loop i from: 0 to:length(type_people) - 1{
					data type_people[i] value: propPeople_per_mobility_type[allPossibleMobilityModes[0]].values[i] color: color_per_type[type_people[i]];
				}
			}			
		}
		
		monitor "Number of people moving" value:movingPeople;
		monitor "Mean diversity" value: meanDiversityGlobal;
		
		
	}	
			
			
}


experiment exploration type: batch keep_seed: true until:(cycle>200){
	
	//parameter "Undergraduate student" var:_undergrad min:0.0 max:1.0 step:0.1;
	//parameter "Graduate student" var: divacc_grad min:0.0 max: 1.0 step:0.1;
	//parameter "PhD student" var: divacc_PhD min:0.0 max:1.0 step:0.1;
	//parameter "Young Professional" var: divacc_youngProf min: 0.0 max:1.0 step:0.1;
	//parameter "Mid-career worker" var:divacc_midCareer min:0.0 max:1.0 step:0.1;
	//parameter "Executives" var:divacc_exec min:0.0 max:1.0 step:0.1;
	//parameter "Worker" var: divacc_worker min:0.0 max: 1.0 step:0.1;
	//parameter "Retiree" var: divacc_retiree min: 0.0 max: 1.0 step:0.1;
		
	int num<-0;	
	reflex save_results_explo{
		save[int(self), divacc_list, peopleMovingRecord, meanDiversityRecord] type:csv to:"../results/results"+ num +".csv" rewrite: true header:true;
		save[int(self), FinalLocation, typeFinalLocation] to:"../results/FinalLocation" + num +".csv" type:"csv" rewrite:true header:true;		
		num<-num+1;
	}
}
