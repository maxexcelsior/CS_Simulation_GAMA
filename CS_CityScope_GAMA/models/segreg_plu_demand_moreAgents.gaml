/***
* Name: segregpludemandmoreAgents
* Author: mirei
* Description: 
* Tags: Tag1, Tag2, TagN
* Agentes multiplos de 10¿?¿?
***/

model segregpludemandmoreAgents

global{
	int agent_per_point <- 10;
	int totalSupportedPeople <- 0;
	map<string,int> possible_unitSizes <- ["S"::1,"M"::2,"L"::3];
	int happyUnitSizePeople <- 0;
	int happyNeighbourhoodPeople <- 0;
	float empty_perc <- 0.8;
	float rent_incr <- 1.05;
	float rent_decr <- 0.95; 
	float meanRentPeople;
	float meanRentBuilding;
	float meanRentBuildingInit;
	int NumberofChangingRents;
	float increasedBuildingMeanRent;
	list<point> busStop_locations <- [{416.065842541361,872.4406645256535},{295.6297241536236,1539.974425847902},{117.57324879127151,1366.4780559606388},{844.7128639433781,1152.1258495633292},{1223.250124982041,794.9240374419919},{528.8729859709387,115.20351949292453},{303.3080137033162,61.469988319234204}];
	
	bool weatherImpact <- false;
	float weather_of_day min: 0.0 max: 1.0;	
	
	list<float> dist_weights;
	float meanRentnorm <- 0.0;
	float meanDiversityGlobal <- 0.0;
	int movingPeople <- 0;
	float meanTimeToMainActivity;
	map<string,float> people_per_Mobility_now; //proportion
	list<point> FinalLocation <- [];
	list<string> typeFinalLocation <- [];
	list<float> meanDiversityRecord <- [];
	list<int> peopleMovingRecord <- [];
	list<int> happyUnitSizePeopleRecord <- [];
	list<int> happyNeighbourhoodPeopleRecord <- [];
	list<float> meanTimeRecord <- [];
	list<map> proportionMobilityRecord;
	list<float> meanRentRecord <- [];
	list<float> meanRentBuildingRecord <- [];
	map<string,int> density_map <- ["S"::15,"M"::55, "L"::89];
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
	list<string> allPossibleMobilityModes <- ["walking","car","bike","bus"];
	map<string,int> nPeople_per_mobility;
	list<string> interesting_buildings <- [];

	
	
	int nb_people <- 1500*agent_per_point;
	list<string> type_people;
	//los operarios habra que ponerlos en algun amenity no en oficina	
	map<string,rgb> color_per_type;
	map<string,float> priceImp_list;
	map<string,float> divacc_list;
	map<string,string> unitSize_list;
	map<string,float> unitSizeWeight_list;
	map<string,string> pattern_list;
	map<string,float> patternWeight_list;
	
	file weight_distances_file <- file("./../includes/Game_IT/WeightDistances.csv");
	file criteria_home_file <- file("./../includes/Game_IT/CriteriaHome.csv");
	string case_study <- "volpe";
	string cityGISFolder <- "./../includes/City/"+case_study;
	file<geometry>buildings_shapefile <- file<geometry>(cityGISFolder+"/Buildings.shp");
	file<geometry> roads_shapefile <- file<geometry>(cityGISFolder+"/Roads.shp");
	file activity_file <- file("./../includes/Game_IT/ActivityPerProfile.csv");
	file mode_file <- file("./../includes/Game_IT/Modes.csv");
	file criteria_file <- file("./../includes/Game_IT/CriteriaFile.csv");
	file profile_file <- file("./../includes/Game_IT/Profiles.csv");
	file weather_coeff <- file("../includes/Game_IT/weather_coeff_per_month.csv");
	geometry shape <- envelope(roads_shapefile);
	
	init{
		do read_priceWeights;
		do read_criteriaHome;
		do createCity;
		do createBuildings;
		do countTotalSupportedPeople;
		//do modifyBuildingsDensity;
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
		do createPopulation;
		do initcalculateDiversityBuilding;
		do countMobility;	
		do countRent;
		do countHappyPeople;
		do countNumberofChangingRents;	
	}
	
	action read_priceWeights{
		matrix dist_weights_matrix <- matrix(weight_distances_file);
		loop i from:0 to: dist_weights_matrix.rows-1{
			dist_weights << dist_weights_matrix[1,i];
		}
		loop i from:2 to: dist_weights_matrix.rows-1{
			interesting_buildings << dist_weights_matrix[0,i];
		}
	}
	
	action read_criteriaHome{
		matrix criteriaHome_matrix <- matrix(criteria_home_file);
		loop i from: 0 to: criteriaHome_matrix.rows -1 {
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
		create city number: 1 {
			minRent<-0.0;
			maxRent<-100.0;	
		}
	}
	
	action createBuildings{
		create building from: buildings_shapefile with:[usage::string(read("Usage")),scale::string(read("Scale")),category::string(read("Category")), FAR::float(read("FAR")), max_height::float(read("Max_Height")), type::string(read("TYPE")), neighbourhood::string(read("NAME"))] {
			myCity <- one_of(city);
			area <- shape.area;
			perimeter <- shape.perimeter;	
			nbFloors <- int(max_height/10); //10 feet per floor
			if (density_map[scale]!=0 and usage="R"){
				supported_people <- int((area/density_map[scale])*nbFloors);
			}
			else{
				supported_people<-0;
			}
			vacant <- supported_people;	
		}
	}
	
	
	action createRoads{
		create road from: roads_shapefile {
			mobility_allowed <- ["walking","bike","car","bus"];
			capacity <- shape.perimeter / agent_per_point; 
			congestion_map [self] <- shape.perimeter;
		}
	}
	
	action createBusStop{
		int cont <- 0;
		create bus_stop number:length(busStop_locations){
			location <- busStop_locations[cont];
			cont <- cont + 1;
		}
	}
	
	action createTStop{
		create T_stop number: 1 {
			//located_building <- building where (each.name = "building261");
			//location<-any_location_in(located_building);
			location <- {956.800386569075,1163.5265618864044,0.0};
		}
	}
	
	action calculateAbsRent{
		ask building where(each.usage = "R"){
			distances <- calculateDistances();
			rentPriceabs <- calculateRent();
		}
	}
	
	action calculateNormRent{
		ask building where(each.usage = "R"){
			rentPriceNormInit <- normalise_rent();
			do changeColorPrice(rentPriceNormInit);
			rentPriceNorm <- rentPriceNormInit; //initially they are both equal
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
		loop type_i over: type_people {
			crits <- weights_map[type_i];
			if (main_activity_map[type_i] in ["OS","OM","OL"]){
				main_activity_code <- first(main_activity_map[type_i]);
			}
			else{
				main_activity_code <- main_activity_map[type_i];
			}
			crits_main_activity <- crits[main_activity_code];
			time_importance_per_type[type_i] <- crits_main_activity[1];
		}
	}
	
	
	action characteristic_file_import{
		matrix mode_matrix <- matrix(mode_file);
		loop i from:0 to: mode_matrix.rows - 1 {
			string mobility_type <- mode_matrix[0,i];
			if(mobility_type!=""){
				list<float> vals <- [];
				loop j from: 1 to: mode_matrix.columns - 2 {
					vals << float(mode_matrix[j,i]);
				}
				charact_per_mobility[mobility_type] <- vals;
				color_per_mobility[mobility_type] <- rgb(mode_matrix[7,i]);
				width_per_mobility[mobility_type] <- float(mode_matrix[8,i]);
				speed_per_mobility[mobility_type] <- float(mode_matrix[9,i]);
				weather_coeff_per_mobility[mobility_type] <- float(mode_matrix[10,i]);
			}
		}		
	}
	
	action profils_data_import{
		matrix profile_matrix<- matrix(profile_file);
		loop i from: 0 to: profile_matrix.rows-1{
			string profil_type<-profile_matrix[0,i];
			if(profil_type!=""){
				color_per_type[profil_type] <- rgb(profile_matrix[1,i]);
				proba_car_per_type[profil_type] <- float(profile_matrix[2,i]);
				proba_bike_per_type[profil_type] <- float(profile_matrix[3,i]);
				proportion_per_type[profil_type] <- float(profile_matrix[4,i]);
			}
		}	
	}
	
	action import_weather_data{
		matrix weather_matrix <- matrix(weather_coeff);
		loop i from:0 to: weather_matrix.rows - 1 {
			weather_of_month << [float(weather_matrix[1,i]),float(weather_matrix[2,i])];
		}
	}
	
	action calculate_weather{
		list<float> weather_m <- weather_of_month[current_date.month-1];
		weather_of_day <- gauss(weather_m[0],weather_m[1]);
	}
	
	action compute_graph{
		loop mobility_mode over: color_per_mobility.keys{
			graph_per_mobility[mobility_mode] <- as_edge_graph (road where (mobility_mode in each.mobility_allowed)) use_cache false;
		}
	}
	
	action createPopulation{
		create people number: nb_people/agent_per_point {
			type <- proportion_per_type.keys[rnd_choice(proportion_per_type.values)];
			priceImportance <- priceImp_list[type];
			living_place <- one_of(building where (each.usage="R" and each.vacant >= 1*agent_per_point));
			living_place.vacant <- living_place.vacant - 1*agent_per_point;			
			priorHouse << living_place;
			exploredHouse << living_place;
			location <- any_location_in(living_place);
			color <- color_per_type[type];
			actualUnitSize <- living_place.scale;
			actualNeighbourhood <- living_place.neighbourhood;
			unitSizeWeight <- calculate_unitSizeWeight(actualUnitSize);
			actualPatternWeight <- calculate_patternWeight(actualNeighbourhood);
			if (living_place.scale = unitSize_list[type]){
				happyUnitSize <- 1;
			}
			else{
				happyUnitSize <- 0;
			}
			if (living_place.neighbourhood = pattern_list[type]){
				happyNeighbourhood <- 1;
			}
			else{
				happyNeighbourhood <- 0;
			}
			principal_activity <- main_activity_map[type];
			
			if (first(principal_activity) = "O"){
				activity_place <- one_of(building where (each.category='O'));
			}
			else if (principal_activity = "restaurant"){//spelling difference with respect to "R" to have different first letter
				activity_place <- one_of(building where(each.category = "Restaurant"));
			}
			else if (principal_activity = "A"){
				activity_place <- one_of(building where(each.category != "R" and each.category != "O"));
			}
			else{
				activity_place <- one_of(building where (each.category = principal_activity));
			}
			do calculate_possibleMobModes;
			map<string,float> mobilityAndTime <- evaluate_main_trip(living_place,activity_place);
			time_main_activity <- mobilityAndTime.values[0];
			mobility_mode_main_activity <- mobilityAndTime.keys[0];
			
		}
	}
	
	action countRent{
		meanRentPeople <- mean(people collect each.living_place.rentPriceNorm);
		if(cycle=0){
			meanRentBuildingInit <- mean(building where(each.usage = "R") collect each.rentPriceNorm);
			meanRentBuilding <- meanRentBuildingInit;
		}
		if(cycle!=0){
			increasedBuildingMeanRent <- ((mean(building where(each.usage = "R") collect each.rentPriceNorm))-meanRentBuildingInit)*100;
		}
		meanRentBuilding <- mean(building where(each.usage = "R") collect each.rentPriceNorm);
	}
	
	action countHappyPeople{
		happyUnitSizePeople <- (people count(each.happyUnitSize = 1))*agent_per_point;
		happyNeighbourhoodPeople <- (people count(each.happyNeighbourhood = 1))*agent_per_point;
	}
	
	action countMobility{
		loop i from: 0 to: length(allPossibleMobilityModes)-1 {
			int nPeople <- (people count(each.mobility_mode_main_activity = allPossibleMobilityModes[i]))*agent_per_point;
			nPeople_per_mobility[allPossibleMobilityModes[i]] <- nPeople;
			people_per_Mobility_now[allPossibleMobilityModes[i]] <- nPeople/nb_people;
		}
		write nPeople_per_mobility;
		meanTimeToMainActivity <- mean(people collect each.time_main_activity);
	}
	
	action countNumberofChangingRents{
		NumberofChangingRents <- building count(each.changeRent = true);
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
		
		ask building where(each.vacant != each.supported_people){
			do normaliseDiversityBuilding;
		}
		
		ask one_of(building){
			ask myCity{
				do updateMeanDiver;
			}
		}
		
	}
	
	action countTotalSupportedPeople{		
		ask building where(each.usage = "R"){
			totalSupportedPeople <- totalSupportedPeople+supported_people;
		}
		//nb_people<-totalSupportedPeople;
	}
	
	/***
	
	action modifyBuildingsDensity{
		ask building where (each.usage = "R"){
			//supported_people <- int(supported_people/(totalSupportedPeople/nb_people)); //para llenar del todo la ciudad con menos agentes
			//cada agente se representa (totalSupportedPeople/nb_people) veces a sí mismo, su mismo tipo de gente
			supported_people <- int(supported_people/10);
			vacant <- supported_people;
		}
		int total_people <- 0;
		ask building where(each.category = "R"){
			total_people <- total_people + self.supported_people;
		}
		write total_people;
		int remaining_people <- totalSupportedPeople - total_people;
		write remaining_people;
	}***/
	
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
				act_all_day << activity_matrix[j,i];
				string act <- activity_matrix[j,i];
				if(act != current_activity){
					activities[act] <- j;
					current_activity <- act;
					posts <- posts+1;
					list_form << act;
				}
			}
			list<int> repetition_list <- [];
			loop j from:0 to:posts-1 {
				repetition_list << count(act_all_day,each=list_form[j]);
			}
			string main_activity <- "";
			int max_value <- 0;
			loop j from:0 to: length(list_form)-1{
				if (repetition_list[j] > max_value and first(list_form[j]) != "R"){
					main_activity <- list_form[j];
					max_value <- repetition_list[j];
				}	
			}
						
			if (main_activity=""){
				list<string> extended;
				list<string> list_form_larg;
				loop j from:0 to:length(list_form)-1{
					extended <- list_form[j] split_with "|";
					loop i from:0 to: length(extended) -1 {
						if (first(extended[i]) != "R"){
							list_form_larg << extended[i];
						}
					}
				}
				main_activity <- one_of(list_form_larg);
			}
		
			main_activity_map[people_type] <- main_activity;
		}
	}
	
	reflex peopleMove{
		movingPeople <- 0;
		NumberofChangingRents <- 0;
		ask building where(each.changeRent=true){
			changeRent <- false;
		}
		ask people{
			do changeHouse;
		}
		do countRent;
		do countHappyPeople;
		do countMobility;
		do countNumberofChangingRents;
	}
	
	reflex saveLocations when: cycle = 199{
		ask people{
			FinalLocation << living_place.location;
			typeFinalLocation << type;
		}
	}
	
	reflex count{
		peopleMovingRecord << movingPeople;
		meanDiversityRecord << meanDiversityGlobal;
		happyUnitSizePeopleRecord << happyUnitSizePeople;
		happyNeighbourhoodPeopleRecord << happyNeighbourhoodPeople;
		meanTimeRecord << meanTimeToMainActivity;
		proportionMobilityRecord << people_per_Mobility_now;
		meanRentRecord << meanRentPeople;
		meanRentBuildingRecord << meanRentBuilding;
	}
		
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
	
	aspect default{
		draw circle(10) color:color;
	}
	
	
	map<string,float> evaluate_main_trip(building origin,building destination){
		list<list> candidates;
		loop mode over: possibleMobModes{
			list<float> characteristic <- charact_per_mobility[mode];
			list<float> cand;
			float distance <- 0.0;
			using topology(graph_per_mobility[mode]){
				distance <- distance_to(origin.location,destination.location);
			}
			cand << characteristic[0] + characteristic[1]*distance;
			cand << characteristic[2]#mn + distance/speed_per_mobility[mode];
			cand << characteristic[4];
			
			cand << characteristic[5]*(weatherImpact?(1.0 + weather_of_day*weather_coeff_per_mobility[mode]):1.0);
			add cand to: candidates;
		}
		
		//normalisation
		list<float> max_values;
		loop i from:0 to: length(candidates[0])-1{
			max_values << max(candidates collect abs(float(each[i])));
		}
		
		loop cand over:candidates{
			loop i from:0 to: length(cand)-1{
				if (max_values[i] != 0.0){
					cand[i] <- float(cand[i])/max_values[i];
				}
			}
		}
		
		map<string,list<float>> crits <- weights_map[type];
		list<float> vals;
		loop obj over:crits.keys{
			if(obj = destination.category or (destination.category in ["OS","OM","OL"]) and (obj = "O") or (destination.category = "Restaurant" and (obj = "restaurant"))){
				vals <- crits[obj];
				break;
			}
		}
		list<map> criteria_WM;
		loop i from: 0 to: length(vals)-1{
			criteria_WM << ["name"::"crit"+i, "weight"::vals[i]];
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
		float timem <- choice_vector[1];
		map<string,float> mobAndTime <- (poss_mobility_mode_main_activity::timem);
		return mobAndTime;
	}
	
	action calculate_possibleMobModes{
		possibleMobModes <- ["walking"];
		if (flip(proba_car_per_type[type]) = true){
			possibleMobModes << "car";
		}
		if (flip(proba_bike_per_type[type]) = true){
			possibleMobModes << "bike";
		}
		possibleMobModes << "bus";
	}
	
	action changeHouse{
		building possibleMoveBuilding <- one_of(building where(each.usage = "R" and (each.vacant >= 1*agent_per_point and (priorHouse contains each != true and(exploredHouse contains each != true and(each != living_place))))));
		//building possibleMoveBuilding<-one_of(building where(each.usage="R" and each.vacant>0));
		exploredHouse << possibleMoveBuilding;
		float possibleLivingCost <- possibleMoveBuilding.rentPriceNorm;
		float living_cost <- living_place.rentPriceNorm;
		float possibleDiversity <- possibleMoveBuilding.diversity;
		string possibleUnitSize <- possibleMoveBuilding.scale;		
		float possibleUnitSizeWeight <- calculate_unitSizeWeight(possibleUnitSize);
		string possibleNeighbourhood <- possibleMoveBuilding.neighbourhood;
		float possiblePatternWeight <- calculate_patternWeight(possibleNeighbourhood);
		map<string,float> possibleTimeAndMob <- evaluate_main_trip(possibleMoveBuilding,activity_place);
		float possibleTime <- possibleTimeAndMob.values[0];
		string possibleMobility <- possibleTimeAndMob.keys[0];
		list<float> crit <- [priceImp_list[type],divacc_list[type],unitSizeWeight_list[type],patternWeight_list[type],time_importance_per_type[type]];
		list<list> cands <- [[possibleLivingCost,possibleDiversity,possibleUnitSizeWeight,possiblePatternWeight, possibleTime],[living_cost,living_place.diversity,unitSizeWeight,actualPatternWeight, time_main_activity]];
		
		list<map> criteria_WM<-[];
		loop i from:0 to: length(crit)-1{
			criteria_WM << ["name"::"crit"+i, "weight"::crit[i]];
		}		
			
		int choice <- weighted_means_DM(cands,criteria_WM);
		
		if (choice=0){ 
			living_place.vacant <- living_place.vacant + 1*agent_per_point;
			building noLonger_living_place <- living_place;
			//low demand --> rent decrease. Only active when nb_people is really high. Otherwise doesn't make sense
			if (noLonger_living_place.vacant > int(empty_perc*noLonger_living_place.supported_people) and living_place.changeRent = false){
				noLonger_living_place.rentPriceNorm <- noLonger_living_place.rentPriceNorm*rent_decr;
				noLonger_living_place.changeRent <- true;
				ask noLonger_living_place{
					do changeColorPrice(rentPriceNorm);
				}
			}
			possibleMoveBuilding.vacant <- possibleMoveBuilding.vacant - 1*agent_per_point;
			living_place <- possibleMoveBuilding;
			ask noLonger_living_place{
				do calculateDiversityBuilding;
			}
			ask living_place{
				do calculateDiversityBuilding;
				ask myCity{
					do updateCityParams;
				}
			}
			ask building{
				do normaliseDiversityBuilding;
			}
			ask living_place{
				ask myCity{
					do updateMeanDiver;
				}
			}
			priorHouse << living_place;
			location <- any_location_in(living_place);
			//high demand --> rent increase
			if (living_place.vacant < int((1-empty_perc)*living_place.supported_people) and living_place.changeRent = false){
				if(living_place.rentPriceNorm < 1){
					living_place.rentPriceNorm <- living_place.rentPriceNorm*rent_incr;
					living_place.changeRent <- true;
					if (living_place.rentPriceNorm > 1){
						living_place.rentPriceNorm <- 1;
					}
				}
				ask living_place{
					do changeColorPrice(rentPriceNorm);
				}
			}
			movingPeople <- movingPeople + 1*agent_per_point;		
			unitSizeWeight <- possibleUnitSizeWeight;
			actualUnitSize <- living_place.scale;
			actualPatternWeight <- possiblePatternWeight;
			actualNeighbourhood <- living_place.neighbourhood;
			time_main_activity <- possibleTime;
			mobility_mode_main_activity <- possibleMobility;
			
		}
		
		if (living_place.scale = unitSize_list[type]){
			happyUnitSize <- 1;	
		}
		else{
			happyUnitSize <- 0;
		}
		if(living_place.neighbourhood = pattern_list[type]){
			happyNeighbourhood <- 1;
		}
		else{
			happyNeighbourhood <- 0;
		}
	}
	
	float calculate_patternWeight(string possibleNeighbourhood){
		float possible_patternWeight;
		if(possibleNeighbourhood != pattern_list[type]){
			possible_patternWeight <- -1.0;
		}
		else{
			possible_patternWeight <- 1.0;
		}
		return possible_patternWeight;
	}
	
	float calculate_unitSizeWeight (string possibleUnitSize){
		float possibleUnitSizeWeight;
		if(possibleUnitSize!=unitSize_list[type]){
			if (possible_unitSizes[possibleUnitSize]>possible_unitSizes[unitSize_list[type]]){
				possibleUnitSizeWeight <- -1.0;	
			}
			else{
				possibleUnitSizeWeight <- -0.5;
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
	
	action updateCityParams{
		maxRent <- max(building where (each.usage = "R") collect each.rentPriceabs);
		minRent <- min(building where (each.usage = "R") collect each.rentPriceabs);
		meanRent <- mean(building where (each.usage = "R") collect each.rentPriceabs);
	
		meanRentnorm <- (meanRent-minRent)/(maxRent-minRent);
		
		maxdiver <- max(building where (each.usage = "R") collect each.diversity);
		mindiver <- min(building where (each.usage = "R") collect each.diversity);
		}
	
	action updateMeanDiver{
		meandiver <- mean(building where(each.usage = "R" and each.vacant != each.supported_people) collect each.diversityNorm);
		meanDiversityGlobal <- meandiver;
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
	float rentPriceNormInit; //normalised based only on distances
	float rentPriceNorm; //dynamically changing with demand
	rgb colorPrice<-#grey; //red if very expensive, green if cheaper f(dist)
	int vacant;
	float diversity <- 0.0; //Shannon Weaver formula
	float diversityNorm;
	float max_height;
	int nbFloors;
	float FAR;
	string type; //building or ruins or whatever
	int supported_people; //how many people can live in this building
	string neighbourhood;	
	bool changeRent <- false;
	
	list<float> calculateDistances{
		list<float> dist_list <- [];
				
		bus_stop closest_busStop <- bus_stop with_min_of(each distance_to (self));
		float dist_busStop <- distance_to(location,closest_busStop.location);
		dist_list << dist_busStop;
		
		T_stop closest_TStop <- T_stop with_min_of(each distance_to (self));
		float dist_TStop <- distance_to(location,closest_TStop.location);
		dist_list << dist_TStop;
		
		building closest_i;
		float dist_i;
		loop i from: 0 to: length(interesting_buildings) - 1 {
			if (category != interesting_buildings[i]){
				closest_i <- building where(each.category = interesting_buildings[i]) with_min_of(each distance_to(self));
				dist_i <- distance_to(location,closest_i.location);
				dist_list << dist_i;
			}
			else{
				dist_list << 0.0;
			}
		}
		return dist_list;
	}
	
	float calculateRent{
		float rent_acum <- 1;
		loop i from: 0 to:length(dist_weights) -1 {
			rent_acum <- rent_acum + 1/1000000*distances[i]*dist_weights[i];
		}
		float rentPrice <- rent_acum;
		return rentPrice;
	}
	
	
	float normalise_rent{
		float maxRentCity;
		float minRentCity;
		float meanRentCity;
		ask myCity{
			do updateCityParams;
			maxRentCity <- maxRent;
			minRentCity <- minRent;

			
		}
		float rentPriceNorm_gen;
		if (maxRentCity != minRentCity){
			rentPriceNorm_gen <- (rentPriceabs-minRentCity)/(maxRentCity-minRentCity);
		}
		else{
			rentPriceNorm_gen <- 0.0;
		}
		
		return rentPriceNorm_gen;
	}
	
	action calculateDiversityBuilding{
		
		diversity <- 0.0;
		
		int people_livingnum <- supported_people - vacant;
		
		if (people_livingnum != 0){
			
			list<int> number_each <- [];
			list<float> proportion_each <- [];
			
			loop i from: 0 to: length(type_people) - 1 {
				number_each << (people count (each.living_place = self and each.type = type_people[i]))*agent_per_point;
				proportion_each << number_each[i]/people_livingnum;
			}
			loop i from:0 to: length(proportion_each) - 1{
				if (proportion_each[i] != 0.0){
					diversity <- diversity + proportion_each[i]*ln(proportion_each[i]);
				}	
			}
			if (diversity != 0.0){
				diversity <- -diversity;
			}
		}
		
		else{
			diversity <- 0.0;
		}
		
	}
	
	action normaliseDiversityBuilding{
		if(myCity.mindiver != myCity.maxdiver){
			diversityNorm <- (diversity-myCity.mindiver)/(myCity.maxdiver-myCity.mindiver);
		}
		else{
			diversityNorm <- 0.0;
		}
	}
	
	action changeColorPrice(float normalised_rent){
		if (usage = "R"){
			float colorPriceValue <- 255*normalised_rent;
			colorPrice <- rgb(max([0,colorPriceValue]),min([255,255-colorPriceValue]),0,125);
		}		
	}
	
	aspect fPrice{
		draw shape color: colorPrice;
	}
	
	aspect default{
		draw shape color: rgb(50,50,50,125);
	}
	
}

species road{
	list<string> mobility_allowed;
	float capacity;
	float max_speed <- 30 #km/#h;
	float current_concentration;
	float speed_coeff <- 1.0;
	
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
			
			overlay position: { 5, 5 } size: { 240 #px, 680 #px } background: # black transparency: 1.0 border: #black 
            {            	
                rgb text_color <- #white;
                float y <- 30#px;
                y <- y + 30 #px;     
                draw "Icons" at: { 40#px, y } color: text_color font: font("Helvetica", 20, #bold) perspective:false;
                y <- y + 30 #px;
                
                draw square(10#px) at: { 20#px, y } color: rgb(0,255,255) border: #white;
                draw string("Undergraduate students") at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 16, #plain) perspective:false;
                y <- y + 25#px;
                
                draw square(10#px) at: { 20#px, y } color: #blue border: #white;
                draw string("Graduate students") at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 16, #plain) perspective:false;
                y <- y + 25#px;
                
                draw square(10#px) at: { 20#px, y } color: #yellow border: #white;
                draw string("PhD") at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 16, #plain) perspective:false;
                y <- y + 25#px;
                
                draw square(10#px) at: { 20#px, y } color: #white border: #white;
                draw string("Young Professional") at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 16, #plain) perspective:false;
                y <- y + 25#px;
                
                draw square(10#px) at: { 20#px, y } color: #green border: #white;
                draw string("Mid career Professional") at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 16, #plain) perspective:false;
                y <- y + 25#px;
                
                draw square(10#px) at: { 20#px, y } color: rgb(102,0,102) border: #white;
                draw string("Executives") at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 16, #plain) perspective:false;
                y <- y + 25#px;
                
               	draw square(10#px) at: { 20#px, y } color: rgb(128,128,128) border: #white;
                draw string("Retiree") at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 16, #plain) perspective:false;
                y <- y + 25#px;
                
                draw square(10#px) at: { 20#px, y } color: rgb(128,128,0) border: #white;
                draw string("Worker") at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 16, #plain) perspective:false;
                y <- y + 25#px;
                    
            }
            
		}
	
			
		display Charts {			
			chart "MovingPeople" type: series background: #white position:{0,0} size:{1.0,0.25}{
				data "Moving people in myCity" value:movingPeople color:#blue;
			}
			chart "Mean diversity evolution" type: series background:#white position:{0,0.25} size:{1.0,0.25}{
				data "Mean diversity in myCity" value: meanDiversityGlobal color: #green;
			}
			chart "Number of people happy with their UnitSize" type:series background: #white position:{0,0.5} size:{1.0,0.25}{
				data "Happy unitSize" value: happyUnitSizePeople color: #red;
			}
			chart "Number of people happy with their Neighbourhood" type: series background:#white position: {0,0.75} size:{1.0,0.25}{
				data "Happy Neighbourhood" value: happyNeighbourhoodPeople color: #orange;
			}
				
		}
		
		display Charts2{
			chart "Mean rent" type:series background: #white position:{0,0} size:{1.0, 0.25}{
				data "Mean normalised rent paid by people in myCity" value: meanRentPeople color: #black;
				data "Mean normalised rent of every Residential Building in myCity" value: meanRentBuilding color:#orange;
			}
			chart "Number of buildings changing rents" type:series background: #white position:{0,0.25} size:{1.0,0.25}{
				data "Number of buildings increasing rent because of demand" value: NumberofChangingRents color: #black;
			}
			chart "Increased mean normalised rent" type:series background: # white position:{0,0.50} size:{1.0,0.25}{
				data "Percentage of increased normalised mean rent of every Residential Building in myCity"	value:increasedBuildingMeanRent color:#black;
			}		

		}
		
		display MobilityPie{
			chart "Proportion of people per Mobility Mode" background:#black type: pie style:ring size: {0.5,0.5} position: {0.0,0.0} color: #white axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{
				loop i from: 0 to: length(people_per_Mobility_now.keys)-1	{
				  data people_per_Mobility_now.keys[i] value: people_per_Mobility_now.values[i] color:color_per_mobility[people_per_Mobility_now.keys[i]];
				}
			}
			chart "Mean time to main activity" type: series background: #white position:{0,0.5} size:{1.0,0.5}{
				data "Mean time to main activity" value:meanTimeToMainActivity color:#blue;
			}
		}
		display MobilityCharts{	

			chart "Number of people using cars" type: series background: #white position:{0,0.0} size: {1.0,0.25}{
				data "Number of people using cars in myCity" value: nPeople_per_mobility.values[1] color: #orange;
			}
			chart "Number of people using bikes" type: series background: #white position:{0,0.25} size: {1.0,0.25}{
				data "Number of people using bikes" value: nPeople_per_mobility.values[2] color: #green;
			}
			chart "Number of people using bus" type: series background: #white position:{0,0.5} size: {1.0,0.25}{
				data "Number of people using bus" value: nPeople_per_mobility.values[3] color: #blue;
			}
			chart "Number of people walking" type: series background: #white position:{0,0.75} size: {1.0,0.25}{
				data "Number of people walking" value: nPeople_per_mobility.values[0] color: #red;
			}
			
		}
		
		monitor "Number of people moving" value:movingPeople;
		monitor "Mean diversity" value: meanDiversityGlobal;
		monitor "Total supported people" value: totalSupportedPeople;
		monitor "Total number of people" value: nb_people;
		monitor "Number of people represented by a dot" value: agent_per_point;	
		
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
		
	int num <- 0;	
	reflex save_results_explo{
		save[int(self), divacc_list, peopleMovingRecord, meanDiversityRecord] type:csv to:"../results/results"+ num +".csv" rewrite: true header:true;
		save[int(self), FinalLocation, typeFinalLocation] to:"../results/FinalLocation" + num +".csv" type:"csv" rewrite:true header:true;		
		num <- num + 1;
	}
}

