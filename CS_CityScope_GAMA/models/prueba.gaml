/***
* Name: prueba
* Author: mirei
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model prueba

global{
	
	string case_study<-"volpe";
	string cityGISFolder<-"./../includes/City/"+case_study;
	file<geometry>buildings_shapefile<-file<geometry>(cityGISFolder+"/Buildings.shp");
	
	init{
		do create_building;
	}
	
	action create_building{
		create building from: buildings_shapefile with:[usage::string(read("Usage")),scale::string(read("Scale")),category::string(read("Category")), FAR::float(read("FAR")), max_height::float(read("Max_Height")), type::string(read("TYPE")), neighbourhood::string(read("NAME")), ID::int(read("BUILDING_I")), dorm::int(read("Dorm")), luxury::int(read("Luxury"))]{
		area <- shape.area;
		perimeter <- shape.perimeter;}
	}
}

species building{
	string usage;
	string scale;
	string category;
	float FAR;
	float max_height;
	string type;
	string neighbourhood;
	int ID;
	int dorm;
	int luxury;
	float area;
	float perimeter;
	
	aspect default{
		draw shape color: rgb(50,50,50,125);
	}
}

experiment visual type: gui{
	output{
		display map type: opengl draw_env: false background: #black {
			species building aspect: default;		
		}
	}
}


