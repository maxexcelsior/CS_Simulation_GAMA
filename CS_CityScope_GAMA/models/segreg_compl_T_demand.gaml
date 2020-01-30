/***
* Name: segregcomplTdemand
* Author: 
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model segreg_compl_T_demand

global{
	int totalSupportedPeople <- 0;
	int nb_people;
	int nb_agents <- 10000;
	int realTotalPeople <- 0;
	int realTotalAgents <- 0;
	int precio_doble <- 1; //1 si no queremos que se aplique el doble de importancia en el precio
	int make_positive;
	float minRentGlobal;
	float maxRentGlobal;
	map<string,int> possible_unitSizes<-["S"::1,"M"::2,"L"::3];
	list<int> possible_agents_per_point_list <- [1,10,20,30,40,50,60,70,80,90,100];
	list<int> actual_agents_per_point_list <- [0,0,0,0,0,0,0,0,0,0,0];
	map<int,int> agent_per_point_map;
	map<string,map<int,int>> agent_per_point_type_map;
	map<string,int> actual_number_people_per_type;
	map<string,int> actual_agents_people_per_type;
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
	float meanDiversityGlobal<-0.0;
	int movingPeople<-0;
	float meanTimeToMainActivity;
	map<string,float> meanTimeToMainActivity_perProfile;
	float meanDistanceToMainActivity;
	map<string,float> meanDistanceToMainActivity_perProfile;
	map<string,float> people_per_Mobility_now; //proportion
	map<string,int> density_map<-["S"::15,"M"::55, "L"::89];
	map<string,string> main_activity_map;
	map<string, float> proportion_per_type;
	map<string,int> total_number_agents_per_type;
	map<string,int> reduced_number_agents_per_type;
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
	list<string> allPossibleMobilityModes<-["walking","car","bike","bus", "T"];
	map<string,map<string,float>> propPeople_per_mobility_type <- map([]);
	map<string,map<string,float>> peoplePerNeighbourhoodMap <- map([]);
	map<string,float> peopleProportionInMainCity;
	int peopleInMainCity;
	map<string,int> nPeople_perProfile;
	float meanCommutingCostGlobal;
	map<string,float> meanCommutingCost_perProfile;
	

	list<string> type_people;
	map<string,rgb> color_per_type;	
	map<string,float> priceImp_list;
	map<string,float> divacc_list;
	map<string,string> unitSize_list;
	map<string,float> unitSizeWeight_list;
	map<string,list<string>> pattern_list;
	map<string,float> patternWeight_list;
	
	//file weight_distances_file<-file("./../includes/Game_IT/WeightDistances.csv");
	file weight_distances_file<-file("./../includes/Game_IT/WeightDistances2.csv");
	file criteria_home_file <- file("./../includes/Game_IT/CriteriaHome2.csv");
	string case_study<-"volpe";
	list<string> list_neighbourhoods <- [];
	string cityGISFolder<-"./../includes/City/"+case_study;
	file<geometry>buildings_shapefile<-file<geometry>(cityGISFolder+"/Buildings_Kendall3.shp");
	file<geometry> roads_shapefile<-file<geometry>(cityGISFolder+"/Roads.shp");
	file activity_file <- file("./../includes/Game_IT/ActivityPerProfile.csv");
	file mode_file <- file("./../includes/Game_IT/Modes2.csv");
	file criteria_file <- file("./../includes/Game_IT/CriteriaFile.csv");
	file profile_file <- file("./../includes/Game_IT/Profiles.csv");
	file weather_coeff <- file("../includes/Game_IT/weather_coeff_per_month.csv");
	file planetary_city_doc <- file("../includes/Game_IT/PlanetaryCities2.csv");
	geometry shape<-envelope(roads_shapefile);
	
	init{
		do read_priceWeights;
		do read_criteriaHome;
		do createCity;
		do createBuildings;
		do countTotalSupportedPeople;
		do createRoads;
		do createBusStop;
		do createTStop;
		do calculateAbsRent;
		do calculateNormRent;
		do importPlanetaryCities;
		do criteria_file_import;		
		do characteristic_file_import;
		do profils_data_import;
		do agent_calc;
		do activityDataImport;
		do calc_time_criteria_per_type;
		do import_weather_data;
		if (weatherImpact=true){
			do calculate_weather;
		}
		do compute_graph;
		do createPopulation;
		do countPopulation;
		do countPopMainCity;
		do countNeighbourhoods; //Kendall + planetary
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
			
			string cat_name <- criteriaHome_matrix[5,i];
			list<string> name_list;
			loop cat over: cat_name split_with "|"{
				name_list << cat;
			}
			add name_list at: type_people[i] to: pattern_list;
			patternWeight_list << (type_people[i]::criteriaHome_matrix[6,i]);		
			 
		}
	}
	
	action createCity{
		create city number:1{
			minRent <- 0.0;
			maxRent <- 100.0;	
			name <- "ppal";
		}
	}
	
	action importPlanetaryCities{
		if (case_study = "volpe"){
			list_neighbourhoods <- "Kendall";
		}
		else{
			list_neighbourhoods <- case_study;
		}
		matrix planetary_matrix <- matrix(planetary_city_doc);
		list<float> prices_planetary <- [];
		loop i from:0 to: planetary_matrix.rows - 1{
			float prices_planetary_i <- planetary_matrix[4,i] ;
			prices_planetary_i <- prices_planetary_i / 2; //es por dos habitaciones
			prices_planetary << (prices_planetary_i - minRentGlobal) / (maxRentGlobal - minRentGlobal);
		} 
		int min_price_dorm <- min(building where (each.dorm = 1) collect each.rentPriceNorm) - 1;
		int min_price_planetary <- min(prices_planetary) - 1;
		if(min_price_dorm < min_price_planetary){
			min_price_planetary <- min_price_dorm;
		}
		make_positive <- - min_price_planetary;
		ask building where(each.usage="R"){		
			if (make_positive != -1){
				rentPriceNorm <- (rentPriceNorm + make_positive)/((make_positive + 1)*precio_doble); //entre 1 y 2 los de Kendall. Para que Somerville etc no estén en negativo
			}	
			else{
				rentPriceNorm <- (rentPriceNorm + make_positive) / 2; //entre 1 y 2 los de Kendall. Para que Somerville etc no estén en negativo
			}		
			
		}
		loop i from: 0 to: planetary_matrix.rows - 1{
			create planetary_city{
				name <- planetary_matrix[0,i];
				list_neighbourhoods << name;
				dist <- planetary_matrix[1,i];
				has_T <- planetary_matrix[3,i];
				meanRent <- planetary_matrix[4,i];
				meanRent <- ((meanRent/2) - minRentGlobal) / (maxRentGlobal - minRentGlobal);
				meanRent <- (meanRent + make_positive)/((make_positive + 1)*precio_doble); //para que no estén en negativo
				location_x <- planetary_matrix[5,i];
				location_y <- planetary_matrix[6,i];
				location <- {location_x,location_y};
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
		ask building where(each.usage = "R"){
			do changeColorPrice;
		}
	}
	
	action createBuildings{
		create building from: buildings_shapefile with:[usage::string(read("Usage")),scale::string(read("Scale")),category::string(read("Category")), FAR::float(read("FAR")), max_height::float(read("Max_Height")), type::string(read("TYPE")), neighbourhood::string(read("NAME")), ID::int(read("BUILDING_I")), dorm::int(read("Dorm")), luxury::int(read("Luxury"))] {
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
			capacity <- shape.perimeter / 10.0; //¿?¿?
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
			//do changeColorPrice;
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
				total_number_agents_per_type[profil_type] <- proportion_per_type[profil_type]*nb_people;
				reduced_number_agents_per_type[profil_type] <- proportion_per_type[profil_type]*nb_agents;
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
	
	action agent_calc{
		loop i from: 0 to: length(proportion_per_type) -1 {
			int itshere <- 0;
			actual_agents_per_point_list <- [0,0,0,0,0,0,0,0,0,0,0];
			
			float mean_value_point <- total_number_agents_per_type[type_people[i]] / reduced_number_agents_per_type[type_people[i]];
			
			loop j from: 0 to: length(possible_agents_per_point_list) - 1 {
				float diff <- possible_agents_per_point_list[j] - mean_value_point;
				if (diff > 0){ //que pasa si nunca entra¿?¿? con numeros de gente muuuuuuy grandes
					itshere <- j;
					break;
				}
			}
			
			float howmany <- total_number_agents_per_type[type_people[i]]/possible_agents_per_point_list[itshere];
			int howmany_round <- round(howmany);
			if (howmany_round >  howmany){
				howmany_round <- howmany_round - 1;
			}
			actual_agents_per_point_list[itshere] <- howmany_round;
			int remaining_people <- total_number_agents_per_type[type_people[i]] - howmany_round*possible_agents_per_point_list[itshere];
			int remaining_points <- reduced_number_agents_per_type[type_people[i]] - howmany_round;
			

			loop m from:0 to:itshere - 1{
				if(possible_agents_per_point_list[m]*remaining_points > remaining_people){
					actual_agents_per_point_list[m] <- int(remaining_people/possible_agents_per_point_list[m]);
					remaining_points <- remaining_points - actual_agents_per_point_list[m];
					remaining_people <- remaining_people - actual_agents_per_point_list[m]*possible_agents_per_point_list[m];
					if(m != 1 and m!= 0){
						loop n from: m - 1 to: 0 step: -1{
							if(possible_agents_per_point_list[n]*remaining_points > remaining_people){
								actual_agents_per_point_list[n] <- int(remaining_people/possible_agents_per_point_list[n]);
								remaining_points <- remaining_points - actual_agents_per_point_list[n];
								remaining_people <- remaining_people - actual_agents_per_point_list[n]*possible_agents_per_point_list[n];
							}
						}	
					}
					else{
						actual_agents_per_point_list[0] <- actual_agents_per_point_list[0] + remaining_people;
					}
					break;
				}
			}
			
			int realnumber_PeopleType <- 0;
			int realagents_PeopleType <- 0;
			loop k from: 0 to: length(possible_agents_per_point_list) - 1{
				agent_per_point_map << (possible_agents_per_point_list[k]::actual_agents_per_point_list[k]);
				realnumber_PeopleType <- realnumber_PeopleType + actual_agents_per_point_list[k]*possible_agents_per_point_list[k];
				realagents_PeopleType <- realagents_PeopleType + actual_agents_per_point_list[k];
			}
			add agent_per_point_map at: type_people[i] to: agent_per_point_type_map;
			agent_per_point_map <- map([]);
			actual_number_people_per_type[type_people[i]] <- realnumber_PeopleType;
			actual_agents_people_per_type[type_people[i]] <- realagents_PeopleType;
			realTotalAgents <- realTotalAgents + realagents_PeopleType;
			realTotalPeople <- realTotalPeople + realnumber_PeopleType;
			nb_people <- realTotalPeople;
			nb_agents <- realTotalAgents;
		}
	}
	
	action createPopulation{
		loop i from: 0 to: length(type_people) -1 {
			loop j from: 0 to: length(agent_per_point_type_map[type_people[i]].values) -1 {
				create people number: agent_per_point_type_map[type_people[i]].values[j]{
					type <- type_people[i];
					agent_per_point <- agent_per_point_type_map[type_people[i]].keys[j];
					priceImportance<-priceImp_list[type];
					living_place <- one_of(building where (each.usage="R" and each.vacant >= 1*agent_per_point));
					if (living_place != nil){
						living_place.vacant<-living_place.vacant - 1*agent_per_point;		
						priorHouse << living_place;
						exploredHouse << living_place;
						actualUnitSize <- living_place.scale;
					}
					else{
						living_place <- one_of(sat_building);
						actualUnitSize <- unitSize_list[type];
					}
					location <- any_location_in(living_place);
					payingRent <- living_place.rentPriceNorm;
					actualNeighbourhood <- living_place.neighbourhood;
					color <- color_per_type[type];
					unitSizeWeight <- calculate_unitSizeWeight(actualUnitSize);
					actualPatternWeight <- calculate_patternWeight(actualNeighbourhood);
					if (living_place.scale = unitSize_list[type]){
						happyUnitSize<-1;
					}
					else{
						happyUnitSize<-0;
					}
					list<string> extract_list <- pattern_list[type];
					if (living_place.neighbourhood = extract_list[0]){
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
					//write map_all_planets_transport;
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
		}
	}
	
	action countPopMainCity{
		peopleInMainCity <- 0;
		ask people where(each.living_place.satellite = false){
			peopleInMainCity <- peopleInMainCity + 1*agent_per_point;
		}
	}
	
	action countNeighbourhoods{
		loop i from: 0 to: length(type_people) - 1{
			map<string,float> peoplePerNeighbourhoodPartialMap <- map([]);
			loop j from: 0 to: length(list_neighbourhoods) - 1{
				int number_peopleProfile_here <- 0;
				ask people where(each.type = type_people[i]){
					if((j != 0 and actualNeighbourhood = list_neighbourhoods[j]) or (j = 0 and living_place.satellite = false)){
						number_peopleProfile_here <- number_peopleProfile_here + 1*agent_per_point;
					}
				}
				peoplePerNeighbourhoodPartialMap[list_neighbourhoods[j]] <- number_peopleProfile_here / nPeople_perProfile[type_people[i]];
				if (j = 0){
					peopleProportionInMainCity[type_people[i]] <- number_peopleProfile_here / peopleInMainCity;
				}
			}
			add peoplePerNeighbourhoodPartialMap at: type_people[i] to: peoplePerNeighbourhoodMap;
		}
	}
	
	action countPopulation{
		nPeople_perProfile <- actual_number_people_per_type;
	}
	
	action countRent{
		meanRentPeople <- 0;
		meanRent_perProfile <- [];
		ask people{
			meanRentPeople <- meanRentPeople + living_place.rentPriceNorm*agent_per_point;
		}
		meanRentPeople <- meanRentPeople / nb_people;
		loop i from: 0 to: length(type_people) -1 {
			ask people where(each.type = type_people[i]){
				meanRent_perProfile[type_people[i]] <- meanRent_perProfile[type_people[i]] + living_place.rentPriceNorm*agent_per_point;
			}
			meanRent_perProfile[type_people[i]] <- meanRent_perProfile[type_people[i]] / nPeople_perProfile[type_people[i]];
		}
		
	}
	
	action countHappyPeople{
		happyUnitSizePeople <- 0;
		happyNeighbourhoodPeople <- 0;
		happyUnitSize_perProfile <- [];
		happyNeighbourhood_perProfile <- [];
		ask people{
			if (happyUnitSize = 1){
				happyUnitSizePeople <- happyUnitSizePeople + agent_per_point;
			}
			if (happyNeighbourhood = 1){
				happyNeighbourhoodPeople <- happyNeighbourhoodPeople + agent_per_point;
			}
		}
		happyUnitSizePeople <- happyUnitSizePeople / nb_people;
		happyNeighbourhoodPeople <- happyNeighbourhoodPeople / nb_people;
		
		loop i from: 0 to: length(type_people) -1 {
			ask people where(each.type = type_people[i]){
				if(happyUnitSize = 1){
					happyUnitSize_perProfile[type_people[i]] <- happyUnitSize_perProfile[type_people[i]] + agent_per_point;
				}
				if(happyNeighbourhood = 1){
					happyNeighbourhood_perProfile[type_people[i]] <- happyNeighbourhood_perProfile[type_people[i]] + agent_per_point;
				}
			}
			happyUnitSize_perProfile[type_people[i]] <- happyUnitSize_perProfile[type_people[i]] / nPeople_perProfile[type_people[i]];
			happyNeighbourhood_perProfile[type_people[i]] <- happyNeighbourhood_perProfile[type_people[i]] / nPeople_perProfile[type_people[i]];
		}
	}
	
	action countMobility{
		propPeople_per_mobility_type <- map([]);	
		loop i from: 0 to: length(allPossibleMobilityModes)-1 {
			map<string,float> propPeople_per_mobility_indiv <- [];
			loop j from:0 to: length(type_people) - 1{
				int nPeople <- 0;
				ask people where(each.mobility_mode_main_activity = allPossibleMobilityModes[i]){
					nPeople <- nPeople + agent_per_point;
				}
				people_per_Mobility_now[allPossibleMobilityModes[i]] <- nPeople/nb_people;
				int nPeopleEach <- 0;
				ask people where(each.type = type_people[j] and each.mobility_mode_main_activity = allPossibleMobilityModes[i]){
					nPeopleEach <- nPeopleEach + agent_per_point;				}
				
				propPeople_per_mobility_indiv[type_people[j]] <- nPeopleEach / nPeople_perProfile[type_people[j]];
				add propPeople_per_mobility_indiv at: allPossibleMobilityModes[i] to: propPeople_per_mobility_type;				
			}
		}
		meanTimeToMainActivity <- 0;
		meanDistanceToMainActivity <- 0;
		ask people{
			meanTimeToMainActivity <- meanTimeToMainActivity + time_main_activity*agent_per_point;
			meanDistanceToMainActivity <- meanDistanceToMainActivity + distance_main_activity*agent_per_point;
		}
		meanTimeToMainActivity <- meanTimeToMainActivity / nb_people;
		meanDistanceToMainActivity <- meanDistanceToMainActivity / nb_people;
		
		meanTimeToMainActivity_perProfile <- [];
		meanDistanceToMainActivity_perProfile <- [];
		loop k from:0 to: length(type_people) -1 {
			ask people where(each.type = type_people[k]){
				meanTimeToMainActivity_perProfile[type_people[k]] <- meanTimeToMainActivity_perProfile[type_people[k]] + time_main_activity*agent_per_point;
				meanDistanceToMainActivity_perProfile[type_people[k]] <- meanDistanceToMainActivity_perProfile[type_people[k]] + distance_main_activity*agent_per_point;
			}
			meanTimeToMainActivity_perProfile[type_people[k]] <- meanTimeToMainActivity_perProfile[type_people[k]] / nPeople_perProfile[type_people[k]];
			meanDistanceToMainActivity_perProfile[type_people[k]] <- meanDistanceToMainActivity_perProfile[type_people[k]] / nPeople_perProfile[type_people[k]];
			
		}
		
		ask people where(each.living_place.satellite = false){
			ask living_place.myCity{
				do updateCommutingCosts;
			}
		}
	}
	
	action initcalculateDiversityBuilding{
		ask building where(each.vacant != each.supported_people){
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
		ask building where(each.usage="R" and each.satellite = false){
			totalSupportedPeople<-totalSupportedPeople+supported_people;
		}
		nb_people <- totalSupportedPeople;
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
				do updateCommutingCosts;
			}
		}
		do countRent;
		do countPopMainCity;
		do countNeighbourhoods;
		do countHappyPeople;
		do countMobility;
	}
	
	/***reflex saveLocations when: cycle=199{
		ask people{
			FinalLocation<<living_place.location;
			typeFinalLocation<<type;
		}
	}***/
	
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
	int agent_per_point;
	
	aspect default{
		draw circle(10*(1 + (agent_per_point - 1)/50)) color:color;
	}
	
	map<string,map<string,list<float>>> calculate_planetary_transport {
		map<string,map<string,list<float>>> map_planet_transport;
		map<string,list<float>> each_planet_transport;
		loop i from: 0 to: length(list_planetary_cities) - 1 {
			if (list_planetary_cities[i].has_T = true){
				each_planet_transport <- evaluate_main_trip(list_planetary_cities[i].location,activity_place, list_planetary_cities[i].dist, true);
				do calculate_possibleMobModes;
				//write 'sí entra';
				//write list_planetary_cities[i].name;
			}
			else{
				each_planet_transport <- evaluate_main_trip(list_planetary_cities[i].location,activity_place, list_planetary_cities[i].dist);
			}
			add each_planet_transport at:list_planetary_cities[i] to: map_planet_transport;
		}	
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
	
	map<string,list<float>> evaluate_main_trip(point origin_location,building destination, float distance_original <- nil, bool isthereT <- false){
		list<list> candidates;
		list<float> commuting_cost_list;
		list<float> distance_list;
		list<string> possibleMobModesNow <- [];
		possibleMobModesNow <- possibleMobModes;
		//write 'possibleMobModesNow ' + possibleMobModesNow;
		//write 'possibleMobModes people '+ possibleMobModes;
		
		if (isthereT = true){
			possibleMobModesNow << "T";
		}
		
		loop mode over:possibleMobModesNow{
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
			poss_mobility_mode_main_activity <- possibleMobModesNow[choice];
		}
		else{
			poss_mobility_mode_main_activity <- one_of(possibleMobModesNow);
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
			possibleMobModes<<"bike";
		}
		possibleMobModes<<"bus";
	}
	
	action changeHouse{
		building possibleMoveBuilding <- one_of(building where(each.usage="R" and (each.vacant >= 1*agent_per_point and (priorHouse contains each!=true and(exploredHouse contains each!=true and(each!=living_place))))));
		//building possibleMoveBuilding<-one_of(building where(each.usage="R" and each.vacant>0));
		list<list> cands <- [];
		float living_cost <- living_place.rentPriceNorm;
		float possibleLivingCost;
		float possibleDiversity;
		string possibleUnitSize;
		float possibleUnitSizeWeight;
		string possibleNeighbourhood;
		float possiblePatternWeight;
		float possibleTime;
		float possibleCommutingCost;
		float possibleDistance;
		string possibleMobility;
		if (possibleMoveBuilding != nil){
			exploredHouse<<possibleMoveBuilding;
			possibleLivingCost<-possibleMoveBuilding.rentPriceNorm;
			possibleDiversity <- possibleMoveBuilding.diversityNorm;
			possibleUnitSize<-possibleMoveBuilding.scale;		
			possibleUnitSizeWeight <- calculate_unitSizeWeight(possibleUnitSize);
			possibleNeighbourhood <- possibleMoveBuilding.neighbourhood;
			possiblePatternWeight <- calculate_patternWeight(possibleNeighbourhood);
			map<string,list<float>> possibleTimeAndMob <- evaluate_main_trip(possibleMoveBuilding.location,activity_place); //list<float> es time y commuting_cost respecto a reference_rent
			list<float> possible_extract_list <- possibleTimeAndMob[possibleTimeAndMob.keys[0]];
			possibleTime <- possible_extract_list[0];
			possibleCommutingCost <- possible_extract_list[1];
			possibleMobility <- possibleTimeAndMob.keys[0];
			possibleDistance <- possible_extract_list[2];
			cands <- [[possibleLivingCost+possibleCommutingCost,possibleDiversity,possibleUnitSizeWeight,possiblePatternWeight, possibleTime],[living_cost + CommutingCost,living_place.diversityNorm,unitSizeWeight,actualPatternWeight, time_main_activity]];
		}
		else{
			cands <- [[-#infinity,-#infinity,-#infinity,-#infinity,-#infinity],[living_cost + CommutingCost,living_place.diversityNorm,unitSizeWeight,actualPatternWeight, time_main_activity]];
		}
		
		list<float> crit<- [priceImp_list[type],divacc_list[type],unitSizeWeight_list[type],patternWeight_list[type],time_importance_per_type[type]];
		
		loop i from: 0 to: length(list_planetary_cities) - 1{
			list<float> possiblePlanetaryCand <- map_planets_move_cand[map_planets_move_cand.keys[i]];
			cands << possiblePlanetaryCand;
		}
		list<map> criteria_WM<-[];
		loop i from:0 to: length(crit)-1{
			criteria_WM<<["name"::"crit"+i, "weight"::crit[i]];
		}		
		int choice <- weighted_means_DM(cands,criteria_WM);
		
		if (choice = 0){ 
			living_place.vacant<-living_place.vacant + 1*agent_per_point;
			building noLonger_living_place <- living_place;
			possibleMoveBuilding.vacant<-possibleMoveBuilding.vacant - 1*agent_per_point;
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
			movingPeople<-movingPeople + 1*agent_per_point;		
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
				living_place.vacant<-living_place.vacant + 1*agent_per_point;
				building nolonger_living_place <- living_place;
				living_place <- list_planetary_cities[choice - 2].planetary_building;
				happyUnitSize <- 1; //suponemos que en planetary_city siempre son capaces de encontrar el unitSize que quieren
				location <- any_location_in(living_place);
				ask nolonger_living_place{
					if(satellite = false){
						do calculateDiversityBuilding; 	
					}
				}
				movingPeople <- movingPeople + 1*agent_per_point;
				list<float> extract_cand_list <- map_planets_move_cand[map_planets_move_cand.keys[choice - 2]];
				list extract_features_list <- map_all_planets_features[map_planets_move_cand.keys[choice - 2]];
				map<string,list<float>> extract_transport_map <- map_all_planets_transport[map_all_planets_transport.keys[choice - 2]];
				list extract_transport_list <- extract_transport_map[extract_transport_map.keys[0]];
				unitSizeWeight <- extract_cand_list[2];
				actualUnitSize <- extract_features_list[1];
				actualPatternWeight <- extract_cand_list[3];
				actualNeighbourhood <- extract_features_list[2];
				time_main_activity <- extract_cand_list[4];
				distance_main_activity <- extract_transport_list[2];
				mobility_mode_main_activity <- extract_transport_map.keys[0];
				CommutingCost <- extract_transport_list[1];						
			}
		}
		
		if (living_place.satellite = false){
			if (living_place.scale=unitSize_list[type]){
				happyUnitSize <- 1;	
			}
			else{
				happyUnitSize <- 0;
			}
		}
		list<string> extract_list <- pattern_list[type];
		if(living_place.neighbourhood = extract_list[0]){
			happyNeighbourhood <- 1;
		}
		else{
			happyNeighbourhood <- 0;
		}
		
	}
		
	float calculate_patternWeight(string possibleNeighbourhood){
		float possible_patternWeight;
		list<string> extract_list <- pattern_list[type];
		int donde <- 1000;
		loop i from: 0 to: length(extract_list) - 1 {
			if (possibleNeighbourhood = extract_list[i]){
				donde <- i;
			}
		}
		
		possible_patternWeight <- 1.0 - donde*0.3;
		if (possible_patternWeight < - 1.0){
			possible_patternWeight <- -1.0;
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
		maxRent<- max(building where (each.usage="R" and each.myCity = self and each.dorm = 0 and each.luxury = 0) collect each.rentPriceabs);
		minRent <- min(building where (each.usage="R" and each.myCity = self and each.dorm = 0 and each.luxury = 0) collect each.rentPriceabs);
		minRentGlobal <- minRent;
		maxRentGlobal <- maxRent;
		meanRent<- mean(building where (each.usage="R" and each.myCity = self) collect each.rentPriceabs);
	
		meanRentnorm<-(meanRent-minRent)/(maxRent-minRent);
		
		maxdiver<-max(building where (each.usage = "R" and each.myCity = self) collect each.diversity);
		mindiver<-min(building where (each.usage = "R" and each.myCity = self) collect each.diversity);
		
	}
	
	action updateMeanDiver{
		meandiver<-mean(building where(each.usage="R" and each.vacant!=each.supported_people and each.myCity = self) collect each.diversityNorm);
		meanDiversityGlobal<-meandiver;
	}
	
	action updateCommutingCosts{
		meanCommutingCostGlobal <- 0;
		ask people{
			meanCommutingCostGlobal <- meanCommutingCostGlobal + CommutingCost*agent_per_point;
		}
		meanCommutingCostGlobal <- meanCommutingCostGlobal / nb_people;
		
		meanCommutingCost_perProfile <- [];
		loop i from: 0 to: length(type_people) - 1 {
			ask people where(each.type = type_people[i]){
				meanCommutingCost_perProfile[type_people[i]] <- meanCommutingCost_perProfile[type_people[i]] + CommutingCost*agent_per_point;
			}
			meanCommutingCost_perProfile[type_people[i]] <- meanCommutingCost_perProfile[type_people[i]] / nPeople_perProfile[type_people[i]];
		}
	}
}

species planetary_city parent: city {
	float dist; //distance to main city
	bool has_T; //(semi-)direct T from/to Kendall
	float location_x;
	float location_y;
	building planetary_building;
	
	aspect basic{
		draw square(20#px) color: rgb(220,220,220,125);
	}
} 

species building{
	int ID;
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
	int dorm;
	int luxury;
	
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
		//float rent_acum<-1;
		//float rent_acum <- 2.6943e03;
		float rent_acum <- 3.164828564568120e+03;// – 0.157640775056889*dist_T - 0.137361376377043*dist_uni  
		loop i from: 0 to:length(dist_weights) - 1 {
			//rent_acum<-rent_acum+1/1000000*distances[i]*dist_weights[i];
			rent_acum<-rent_acum+distances[i]*dist_weights[i];
		}
		float rentPrice <- rent_acum / 2; // los calculos son para 2 habitaciones. Buscamos precio por habitacion
		
		if (dorm = 1){
			rentPrice <- rentPrice * 0.75; //reducimos el valor del precio en caso de que sea dorm
		}
		if (luxury = 1){
			rentPrice <- rentPrice * 1.5; //aumentamos el valor del precio en caso de que sea un edif de lujo
		}
		
		return rentPrice;
	}
	
	
	float normalise_rent{
		float maxRentCity;
		float minRentCity;
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
		
		return rentPriceNorm_gen;
	}
	
	action calculateDiversityBuilding{
		
		diversity<-0.0;
		
		int people_livingnum<-supported_people-vacant;
		
		if (people_livingnum!=0){
			
			list<int> number_each <- [];
			list<float> proportion_each <- [];
			
			loop i from: 0 to: length(type_people)-1 {
				//number_each << people count (each.living_place=self and each.type=type_people[i]);
				int number_each_indiv <- 0;
				ask people where(each.living_place = self and each.type = type_people[i]){
					number_each_indiv <- number_each_indiv + agent_per_point;
				}
				number_each << number_each_indiv;
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
			float colorPriceValue<-255*(rentPriceNorm*(make_positive + 1)*precio_doble-make_positive);
			//float colorPriceValue<-255*(rentPriceNorm-make_positive);
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
			chart "Proportion of people per Mobility Mode" background:#white type: pie style:ring size: {0.25,0.25} position: {0.0,0.0} color: #black axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
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
				loop i from: 0 to:length(type_people) - 1{
					data type_people[i] value: propPeople_per_mobility_type[allPossibleMobilityModes[1]].values[i] color: color_per_type[type_people[i]];
				}
			}
			chart "Proportion of people using bikes" type: series background: #white position:{0,0.5} size: {1.0,0.5}{
				data "Mean proportion of people" value: people_per_Mobility_now.values[2] color: #black;
				loop i from: 0 to:length(type_people) - 1{
					data type_people[i] value: propPeople_per_mobility_type[allPossibleMobilityModes[2]].values[i] color: color_per_type[type_people[i]];
				}
			}	
		}
		display MobilityChartsBusWalking{
			chart "Proportion of people using bus" type: series background: #white position:{0,0.0} size: {1.0,0.5}{
				data "Mean proportion of people" value: people_per_Mobility_now.values[3] color: #black;
				loop i from: 0 to:length(type_people) - 1{
					data type_people[i] value: propPeople_per_mobility_type[allPossibleMobilityModes[3]].values[i] color: color_per_type[type_people[i]];
				}
			}
			chart "Proportion of people walking" type: series background: #white position:{0,0.5} size: {1.0,0.5}{
				data "Mean proportion of people" value: people_per_Mobility_now.values[0] color: #black;
				loop i from: 0 to:length(type_people) - 1{
					data type_people[i] value: propPeople_per_mobility_type[allPossibleMobilityModes[0]].values[i] color: color_per_type[type_people[i]];
				}
			}			
		}
		display MobilityChartsT{
			chart "Proportion of people using T" type: series background: #white position:{0,0.0} size: {1.0,0.5}{
				data "Mean proportion of people" value: people_per_Mobility_now.values[4] color: #black;
				loop i from: 0 to:length(type_people) - 1{
					data type_people[i] value: propPeople_per_mobility_type[allPossibleMobilityModes[4]].values[i] color: color_per_type[type_people[i]];
				}
			}
		}
		display PeoplePerNeighbourhood{			
			chart "Proportion of people per neighbourhood [Undergrad]" background:#white type: pie style:ring size: {0.3,0.3} position: {0.0,0.0} color: #black axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{					
					loop i from: 0 to: length(peoplePerNeighbourhoodMap[type_people[0]].keys)-1	{
					  data peoplePerNeighbourhoodMap[type_people[0]].keys[i] value:peoplePerNeighbourhoodMap[type_people[0]].values[i];
					}
			}
			chart "Proportion of people per neighbourhood [Grad]" background:#white type: pie style:ring size: {0.3,0.3} position: {0.3,0.0} color: #black axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{					
					loop i from: 0 to: length(peoplePerNeighbourhoodMap[type_people[1]].keys)-1	{
					  data peoplePerNeighbourhoodMap[type_people[1]].keys[i] value:peoplePerNeighbourhoodMap[type_people[1]].values[i];
					}
			}
			chart "Proportion of people per neighbourhood [PhD]" background:#white type: pie style:ring size: {0.3,0.3} position: {0.6,0.0} color: #black axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{					
					loop i from: 0 to: length(peoplePerNeighbourhoodMap[type_people[2]].keys)-1	{
					  data peoplePerNeighbourhoodMap[type_people[2]].keys[i] value:peoplePerNeighbourhoodMap[type_people[2]].values[i];
					}
			}
			chart "Proportion of people per neighbourhood [YoungProf]" background:#white type: pie style:ring size: {0.3,0.3} position: {0.0,0.3} color: #black axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{					
					loop i from: 0 to: length(peoplePerNeighbourhoodMap[type_people[3]].keys)-1	{
					  data peoplePerNeighbourhoodMap[type_people[3]].keys[i] value:peoplePerNeighbourhoodMap[type_people[3]].values[i];
					}
			}
			chart "Proportion of people per neighbourhood [MidCareer]" background:#white type: pie style:ring size: {0.3,0.3} position: {0.3,0.3} color: #black axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{					
					loop i from: 0 to: length(peoplePerNeighbourhoodMap[type_people[4]].keys)-1	{
					  data peoplePerNeighbourhoodMap[type_people[4]].keys[i] value:peoplePerNeighbourhoodMap[type_people[4]].values[i];
					}
			}
			chart "Proportion of people per neighbourhood [Executives]" background:#white type: pie style:ring size: {0.3,0.3} position: {0.6,0.3} color: #black axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{					
					loop i from: 0 to: length(peoplePerNeighbourhoodMap[type_people[5]].keys)-1	{
					  data peoplePerNeighbourhoodMap[type_people[5]].keys[i] value:peoplePerNeighbourhoodMap[type_people[5]].values[i];
					}
			}
			chart "Proportion of people per neighbourhood [Worker]" background:#white type: pie style:ring size: {0.3,0.3} position: {0.0,0.6} color: #black axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{					
					loop i from: 0 to: length(peoplePerNeighbourhoodMap[type_people[6]].keys)-1	{
					  data peoplePerNeighbourhoodMap[type_people[6]].keys[i] value:peoplePerNeighbourhoodMap[type_people[6]].values[i];
					}
			}
			chart "Proportion of people per neighbourhood [Retiree]" background:#white type: pie style:ring size: {0.3,0.3} position: {0.3,0.6} color: #black axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{					
					loop i from: 0 to: length(peoplePerNeighbourhoodMap[type_people[7]].keys)-1	{
					  data peoplePerNeighbourhoodMap[type_people[7]].keys[i] value:peoplePerNeighbourhoodMap[type_people[7]].values[i];
					}
			}
			chart "People distribution in Main City" background:#white type: pie style:ring size: {0.3,0.3} position: {0.6,0.6} color: #black axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{					
					loop i from: 0 to: length(peopleProportionInMainCity.keys)-1	{
					  data peopleProportionInMainCity.keys[i] value:peopleProportionInMainCity.values[i] color: color_per_type[type_people[i]];
					}
			}
		}
		
		monitor "Number of people moving" value:movingPeople;
		monitor "Mean diversity" value: meanDiversityGlobal;
		monitor "Number of people represented" value: nb_people;
		monitor "Number of agents used" value: nb_agents;
		
		
	}	
			
			
}


/***experiment exploration type: batch keep_seed: true until:(cycle>200){
	
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
}***/


