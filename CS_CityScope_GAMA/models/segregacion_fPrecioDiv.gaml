/***
* Name: segregacionfPrecio
* Author: mirei
* Description: 
* Tags: Tag1, Tag2, TagN
* !! se impone restricción de que no pueden volver a mudarse a la misma casa pq ha cambiado
* la diversidad en esta
***/

model segregacionfPrecioDiv


global{
	
	float wgd_HS<- 0.0;
	float wgd_uni<- -1;
	float wgd_comm<- -0.1;
	float wgd_busStop <- -0.2;
	float wgd_Tstop<- -0.75;
	float wgd_cultural <- 0.0;
	float wgd_rest<- 0.0;
	float wgd_night<- 0.0;
	float wgd_park<- -0.05;
	
	float prop_undergrad<-0.15;
	float prop_grad<-0.15;
	float prop_PhD<-0.05;
	float prop_youngProf<-0.15;
	float prop_midCareer<-0.2;
	float prop_exec<-0.2;
	float prop_worker<-0.05;
	float prop_retiree<-0.05;
	
	float priceImp_undergrad<- -1.0;
	float priceImp_grad<- -0.95;
	float priceImp_PhD<- -0.7;
	float priceImp_youngProf<- -0.5;
	float priceImp_midCareer<- -0.4;
	float priceImp_exec<- -0.1;
	float priceImp_worker<- -0.8;
	float priceImp_retiree<- -0.5;
	
	float divacc_undergrad<- 0.3;
	float divacc_grad<- 0.3;
	float divacc_PhD<- 0.1;
	float divacc_youngProf<- 0.0;
	float divacc_midCareer<- -0.1;
	float divacc_exec<- - 0.3;
	float divacc_worker<- 0.0;
	float divacc_retiree<- -0.5;
	
	list<float> dist_weights<- [wgd_HS, wgd_uni, wgd_comm, wgd_busStop, wgd_Tstop, wgd_cultural,wgd_rest,wgd_night,wgd_park];
	float meanRentnorm<-0.0;
	int initVacant<-5;	
	float meanDiversityGlobal<-0.0;
	float gemomeanDiversityGlobal<-0.0;
	int movingPeople<-0;
	list<point> FinalLocation<-[];
	list<float> meanDiversityRecord<-[];
	list<int> peopleMovingRecord<-[];
	
	int nb_people<-15;
	list<string> type_people<-["Undergraduate student", "Graduate student", "PhD", "Young Professional", "Mid-career Professional", "Executives", "Worker", "Retiree"];
	//los operarios habra que ponerlos en algun amenity no en oficina
	map<string,rgb> color_per_type<-["Undergraduate student"::#pink, "Graduate student"::#blue, "PhD"::#yellow, "Young Professional"::#white, "Mid-career Professional"::#green, "Executives"::rgb(102,0,102),"Worker"::rgb(128,128,0), "Retiree"::rgb(128,128,128)];	
	map<string,float> prop_list<-["Undergraduate student"::prop_undergrad,"Graduate student"::prop_grad,"PhD"::prop_PhD,"Young Professional"::prop_youngProf,"Mid-career Professional"::prop_midCareer,"Executives"::prop_exec,"Worker"::prop_worker,"Retiree"::prop_retiree];
	map<string,float> priceImp_list<-["Undergraduate student"::priceImp_undergrad,"Graduate student"::priceImp_grad,"PhD"::priceImp_PhD, "Young Professional"::priceImp_youngProf,"Mid-career Professional"::priceImp_midCareer,"Executives"::priceImp_exec, "Worker"::priceImp_worker,"Retiree"::priceImp_retiree];
	map<string,float> divacc_list<-["Undergraduate student"::divacc_undergrad,"Graduate student"::divacc_grad,"PhD"::divacc_PhD, "Young Professional"::divacc_youngProf,"Mid-career Professional"::divacc_midCareer,"Executives"::divacc_exec, "Worker"::divacc_worker,"Retiree"::divacc_retiree];
	
	string case_study<-"volpe";
	string cityGISFolder<-"./../includes/City/"+case_study;
	//file<geometry> buildings_shapefile<-file<geometry>(cityGISFolder+"/Buildings.shp"); //only for volpe
	file<geometry>buildings_shapefile<-file<geometry>(cityGISFolder+"/buildingo2_NAD.shp");
	file<geometry> roads_shapefile<-file<geometry>(cityGISFolder+"/Roads.shp");
	geometry shape<-envelope(roads_shapefile);
	
	init{
		do createCity;
		do createBuildings;
		do createRoads;
		do createBusStop;
		do createTStop;
		do calculateAbsRent;
		do calculateNormRent;
		do createPopulation;
		do initcalculateDiversityBuilding;
		
	}
	
	action createCity{
		create city number:1{
			minRent<-0.0;
			maxRent<-100.0;	
		}
	}
	
	action createBuildings{
		create building from: buildings_shapefile with:[usage::string(read("Usage")),scale::string(read("Scale")),category::string(read("Category"))] {
			myCity<-one_of(city);
			area<-shape.area;
			perimeter<- shape.perimeter;
			vacant<-initVacant;		
		}
	}
	
	
	action createRoads{
		create road from: roads_shapefile;
	}
	
	action createBusStop{
		create bus_stop number:6{
			location <- one_of(building).location;
		}
	}
	
	action createTStop{
		create T_stop number:1{
			location<- one_of(building).location;
		}
	}
	
	action calculateAbsRent{
		ask building{
			distances<-calculateDistances();
			rentPriceabs<-calculateRent();
		}
	}
	
	action calculateNormRent{
		ask building{
			rentPriceNorm<-normalise_rent();
			do changeColorPrice;
		}
	}
	
	action createPopulation{
		create people number:nb_people{
			type<-prop_list.keys[rnd_choice(prop_list.values)];
			priceImportance<-priceImp_list[type];
			living_place<-one_of(building where (each.usage="R" and each.vacant>0));
			living_place.vacant<-living_place.vacant-1;			
			priorHouse<<living_place;
			exploredHouse<<living_place;
			location<-any_location_in(living_place);
			color<-color_per_type[type];
		}
	}
	
	action initcalculateDiversityBuilding{
		ask building where(each.vacant!=initVacant){
			do calculateDiversityBuilding;
		}
		
		ask one_of(building){
			ask myCity{
				do updateCityParams;
			}			
		}
		
		ask building where(each.vacant!=initVacant){
			do normaliseDiversityBuilding;
		}
		
	}
	
	reflex peopleMove{
		movingPeople<-0;
		ask people{
			do changeHouse;
		}
	}
	
	reflex saveLocations when: cycle=199{
		ask people{
			FinalLocation<<living_place.location;
		}
	}
	
	reflex count{
		peopleMovingRecord<<movingPeople;
		meanDiversityRecord<<meanDiversityGlobal;
	}
		
}

species people{
	string type;
	float priceImportance;
	rgb color;
	building living_place;
	list<building> priorHouse;
	list<building> exploredHouse;
	
	aspect default{
		draw circle(30) color:color;
	}
	
	action changeHouse{
		building possibleMoveBuilding <- one_of(building where(each.usage="R" and (each.vacant>0 and (priorHouse contains each!=true and(exploredHouse contains each!=true and(each!=living_place))))));
		exploredHouse<<possibleMoveBuilding;
		float possibleLivingCost<-possibleMoveBuilding.rentPriceNorm*priceImportance;
		float living_cost <- living_place.rentPriceNorm*priceImportance;
		float possibleDiversity <- possibleMoveBuilding.diversity;
		list<float> crit <- [priceImp_list[type],divacc_list[type]];
		list<list> cands<-[[possibleLivingCost,possibleDiversity],[living_cost,living_place.diversity]];
		
		list<map> criteria_WM;
		loop i from:0 to: length(crit)-1{
			criteria_WM<<["name"::"crit"+i, "weight"::crit[i]];
		}		
		int choice <- weighted_means_DM(cands,criteria_WM);
		
		if (choice=1){ 
			living_place.vacant<-living_place.vacant+1;
			possibleMoveBuilding.vacant<-possibleMoveBuilding-1;
			ask living_place{
				do calculateDiversityBuilding;
			}
			ask possibleMoveBuilding{
				do calculateDiversityBuilding;
				ask myCity{
					do updateCityParams;
				}
			}
			ask building where(each.vacant!=initVacant){
				do normaliseDiversityBuilding;
			}
			
			living_place<-possibleMoveBuilding;
			priorHouse<<living_place;
			location<-any_location_in(living_place);
			movingPeople<-movingPeople+1;		
		}
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
		maxRent<- max(building where (each.usage="R") collect each.rentPriceabs);
		minRent <- min(building where (each.usage="R") collect each.rentPriceabs);
		meanRent<- mean(building where (each.usage="R") collect each.rentPriceabs);
		//write geommeanRent;
	
		meanRentnorm<-(meanRent-minRent)/(maxRent-minRent);
		
		maxdiver<-max(building collect each.diversity);
		mindiver<-min(building collect each.diversity);
		meandiver<-mean(building where(each.usage="R" and each.vacant!=initVacant) collect each.diversity);
		meanDiversityGlobal<-meandiver;
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
	float rentPriceNorm; //normalizado
	rgb colorPrice<-#grey; //rojo si muy caro, verde si más barato f(distancias)
	int vacant;
	float diversity<-0.0; //Shannon Weaver formula
	
	list<float> calculateDistances{
		float dist_HS;
		float dist_uni;
		float dist_comm;
		float dist_busStop;
		float dist_TStop;
		float dist_cultural;
		float dist_rest;
		float dist_night;
		float dist_park;
		
		bus_stop closest_busStop<-bus_stop with_min_of(each distance_to (self));
		dist_busStop<-distance_to(location,closest_busStop.location);
		
		T_stop closest_TStop<-T_stop with_min_of(each distance_to (self));
		dist_TStop<-distance_to(location,closest_TStop.location);
		
		if (category!="Uni"){
			building closest_uni <- building where (each.category = "Uni") with_min_of(each distance_to(self));
			dist_uni<-distance_to(location,closest_uni.location);
		}
		else{
			dist_uni<-0.0;
		}
		
		if(category!="Restaurant"){
			building closest_rest<-building where (each.category = "Restaurant") with_min_of(each distance_to(self));
			dist_rest<-distance_to(location,closest_rest.location);
		}
		else{
			dist_rest<-0.0;
		}
		
		if(category!="Shopping"){
			building closest_comm<-building where(each.category = "Shopping") with_min_of(each distance_to(self));
			dist_comm<-distance_to(location,closest_comm.location);
		}
		else{
			dist_comm<-0.0;
		}
		
		if (category!="Night"){
			building closest_night<- building where(each.category="Night") with_min_of(each distance_to(self));
			dist_night<-distance_to(location,closest_night.location);
		}else{
			dist_night<-0.0;
		}
		if(category!="Park"){
			building closest_park<-building where(each.category="Park") with_min_of(each distance_to(self));
			dist_park<-distance_to(location,closest_park.location);
		}else{
			dist_park<-0.0;
		}
		if (category!="Cultural"){
			building closest_cultural<-building where(each.category="Cultural") with_min_of(each distance_to(self));
			dist_cultural<-distance_to(location,closest_cultural.location);
		}else{
			dist_cultural<-0.0;
		}
		if(category!="HS"){
			building closest_HS<-building where(each.category="HS") with_min_of(each distance_to(self));
			dist_HS<-distance_to(location,closest_HS.location);
		}else{
			dist_HS<-0.0;
		}
		
		list<float> dist_list <-[dist_HS,dist_uni,dist_comm,dist_busStop,dist_TStop,dist_cultural,dist_rest,dist_night,dist_park];
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
			meanRentCity<-meanRent;
			
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
		
		int people_living<-initVacant-vacant;
		
		if (people_living!=0){
			int number_undergrad<- people count (each.living_place=self and each.type="Undergraduate student");
			float proportion_undergrad<-number_undergrad/people_living;
	
			int number_grad<- people count (each.living_place=self and each.type="Graduate student");
			float proportion_grad<-number_grad/people_living;
			
			int number_PhD<- people count (each.living_place=self and each.type="PhD");
			float proportion_PhD<-number_PhD/people_living;
			
			int number_youngProf<- people count (each.living_place=self and each.type="Young Professional");
			float proportion_youngProf<-number_youngProf/people_living;
			
			int number_midCareer<- people count (each.living_place=self and each.type="Mid-career Professional");
			float proportion_midCareer<-number_midCareer/people_living;
			
			int number_exec<- people count (each.living_place=self and each.type="Executives");
			float proportion_exec<-number_exec/people_living;
			
			int number_worker<- people count (each.living_place=self and each.type="Worker");
			float proportion_worker<-number_worker/people_living;
			
			int number_retiree<- people count (each.living_place=self and each.type="Retiree");
			float proportion_retiree<-number_retiree/people_living;
		
			list<float> proplist_building<-[proportion_undergrad,proportion_grad,proportion_PhD,proportion_youngProf,proportion_midCareer,proportion_exec,proportion_worker,proportion_retiree];
		
			loop i from:0 to:length(proplist_building)-1{
				if (proplist_building[i]!=0.0){
					diversity <- diversity + proplist_building[i]*ln(proplist_building[i]);
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
			diversity <- (diversity-myCity.mindiver)/(myCity.maxdiver-myCity.mindiver);
		}
		else{
			diversity<-0.0;
		}
	}
	
	action changeColorPrice{
		if (usage="R"){
			float colorPriceValue<-255*rentPriceNorm;
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

species road{
	
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
	aspect default{
		draw square(10#px) color:#white;
	}
}



experiment visual type:gui{
	
	parameter "Undergraduate student" var:priceImp_undergrad<- -1.0 min:-1.0 max:0.0 category: "Price Importance for: ";
	parameter "Graduate student" var: priceImp_grad<- -0.95 min:-1.0 max: 0.0 category: "Price Importance for: ";
	parameter "PhD student" var: priceImp_PhD<- -0.7 min:-1.0 max:0.0 category:"Price Importance for: ";
	parameter "Young Professional" var: priceImp_youngProf<- -0.5 min: -1.0 max:0.0 category:"Price Importance for: ";
	parameter "Mid-career worker" var:priceImp_midCareer<- -0.4 min:-1.0 max:0.0 category:"Price Importance for: ";
	parameter "Executives" var:priceImp_exec <- -0.1 min:-1.0 max:0.0 category: "Price Importance for: ";
	parameter "Worker" var: priceImp_worker<- -0.8 min:-1.0 max: 0.0 category: "Price Importance for: ";
	parameter "Retiree" var: priceImp_retiree<- -0.5 min: -1.0 max: 0.0 category: "Price Importance for: ";
	
	parameter "Undergraduate student" var:divacc_undergrad<- 0.3 min:-1.0 max:1.0 category: "Diversity Acceptance for: ";
	parameter "Graduate student" var: divacc_grad<- 0.3 min:-1.0 max: 1.0 category: "Diversity Acceptance for: ";
	parameter "PhD student" var: divacc_PhD<- 0.1 min:-1.0 max:1.0 category:"Diversity Acceptance for: ";
	parameter "Young Professional" var: divacc_youngProf<- 0.0 min: -1.0 max:1.0 category:"Diversity Acceptance for: ";
	parameter "Mid-career worker" var:divacc_midCareer<- -0.1 min:-1.0 max:1.0 category:"Diversity Acceptance for: ";
	parameter "Executives" var:divacc_exec <- -0.3 min:-1.0 max:1.0 category: "Diversity Acceptance for: ";
	parameter "Worker" var: divacc_worker<- 0.0 min:-1.0 max: 1.0 category: "Diversity Acceptance for: ";
	parameter "Retiree" var: divacc_retiree<- -0.5 min: -1.0 max: 1.0 category: "Diversity Acceptance for: ";
	
	parameter "Number of people" var: nb_people <- 15 min:100 max:10000 category: "Population";
	output{
		display map type: opengl draw_env: false background: #black {
			species building aspect: fPrice;
			species road;
			species bus_stop aspect: default;
			species T_stop aspect:default;
			species people aspect: default;
			
			overlay position: { 5, 5 } size: { 240 #px, 680 #px } background: # black transparency: 1.0 border: #black 
            {            	
                rgb text_color<-#white;
                float y <- 30#px;
                y <- y + 30 #px;     
                draw "Icons" at: { 40#px, y } color: text_color font: font("Helvetica", 20, #bold) perspective:false;
                y <- y + 30 #px;
                
                draw square(10#px) at: { 20#px, y } color: #pink border: #white;
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
			chart "MovingPeople" type: series background: #white position:{0,0} size:{1.0,0.5}{
				data "Moving people in myCity" value:movingPeople color:#blue;
			}
			chart "Mean diversity evolution" type: series background:#white position:{0,0.5} size:{1.0,0.5}{
				data "Mean diversity in myCity" value: meanDiversityGlobal color: #green;
			}
				
		}
		
		monitor "Number of people moving" value:movingPeople;
		monitor "Mean diversity" value: meanDiversityGlobal;
	}	
			
			
}


experiment exploration type: batch keep_seed: true until:(cycle>200){
	
	parameter "Undergraduate student" var:priceImp_undergrad min:-1.0 max:0.0 step:0.1;
	//parameter "Graduate student" var: priceImp_grad min:-1.0 max: 0.0 step: 0.05;
	//parameter "PhD student" var: priceImp_PhD min:-1.0 max:0.0 step:0.05;
	//parameter "Young Professional" var: priceImp_youngProf min: -1.0 max:0.0 step:0.05;
	//parameter "Mid-career worker" var:priceImp_midCareer min:-1.0 max:0.0 step:0.05;
	//parameter "Executives" var:priceImp_exec min:-1.0 max:0.0 step:0.05;
	//parameter "Worker" var: priceImp_worker min:-1.0 max: 0.0 step:0.05;
	//parameter "Retiree" var: priceImp_retiree min: -1.0 max: 0.0 step:0.05;
	
	//parameter "Undergraduate student" var:divacc_undergrad min:-1.0 max:1.0 step:0.1;
	//parameter "Graduate student" var: divacc_grad min:-1.0 max: 1.0 step:0.1;
	//parameter "PhD student" var: divacc_PhD min:-1.0 max:1.0 step:0.1;
	//parameter "Young Professional" var: divacc_youngProf min: -1.0 max:1.0 step:0.1;
	//parameter "Mid-career worker" var:divacc_midCareer min:-1.0 max:1.0 step:0.1;
	//parameter "Executives" var:divacc_exec min:-1.0 max:1.0 step:0.1;
	//parameter "Worker" var: divacc_worker min:-1.0 max: 1.0 step:0.1;
	//parameter "Retiree" var: divacc_retiree min: -1.0 max: 1.0 step:0.1;
	
	int num<-0;	
	reflex save_results_explo{
		save[int(self), priceImp_undergrad, peopleMovingRecord, meanDiversityRecord] type:csv to:"../results/results"+ num +".csv" rewrite: true header:true;
		save[int(self), FinalLocation] to:"../results/FinalLocation" + num +".csv" type:"csv" rewrite:true header:true;		
		num<-num+1;
	}
}