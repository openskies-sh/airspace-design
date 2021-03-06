/**
* Name: renoutm
* Based on the internal empty template. 
* Author: Hrishikesh Ballal
* Tags: 
*/

model renoutm

/* Insert your model definition here */

global {
    file shape_file_buildings <- file("../includes/downtown-buildings.shp");
    file shape_file_roads <- file("../includes/downtown-roads.shp");
    file shape_file_bounds <- file("../includes/downtown-bounds.shp");
    geometry shape <- envelope(shape_file_bounds);
    // float step <- 1 #mn;
    // date starting_date <- date("2020-09-01-00-00-00");
    int nb_drones <- 100;
 
    float min_speed <- 20.0 #km / #h;
    float max_speed <- 30.0 #km / #h; 
    graph road_graph;    
    
    // Paint the buildings
    init {
    create building from: shape_file_buildings with: [type::string(read ("newlanduse"))] {
        if type="commercial" {
        color <- #blue ;
        }
        if type="residential" {
        color <- #purple;
        }
    }
    create road from: shape_file_roads ;
    road_graph <- as_edge_graph(road);
        
    list<building> residential_buildings <- building where (each.type="residential");
    list<building> industrial_buildings <- building  where (each.type="commercial") ;
    create drones number: nb_drones {
        speed <- rnd(min_speed, max_speed);
        delivery_end <- one_of(residential_buildings) ;
        delivery_start <- one_of(industrial_buildings) ;
        objective <- "resting";
        location <- any_location_in (delivery_start); 
    }
    }
}

species building {
    string type; 
    rgb color <- #gray  ;
    
    aspect base {
    draw shape color: color ;
    }
}

species road  {
    rgb color <- #black ;
    
    aspect base {
    draw shape color: color ;
    }
}

species drones skills:[moving] {
    rgb color <- #yellow ;
    building delivery_end <- nil ;
    building delivery_start <- nil ;
    int start_work ;
    int end_work  ;
    string objective ; 
    point the_target <- nil ;
        
    reflex time_to_work when: objective = "resting"{
    objective <- "working" ;
    the_target <- any_location_in (delivery_start);
    }
        
    reflex time_to_go_home when: objective = "working"{
    objective <- "resting" ;
    the_target <- any_location_in (delivery_end); 
    } 
     
    reflex move when: the_target != nil {
    do goto target: the_target on: road_graph ; 
    if the_target = location {
        the_target <- nil ;
    }
    }
    
    aspect base {
    draw circle(10) color: color border: #black;
    }
}


experiment air_traffic type: gui {
    parameter "Shapefile for the buildings:" var: shape_file_buildings category: "GIS" ;
    parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS" ;
    parameter "Shapefile for the bounds:" var: shape_file_bounds category: "GIS" ;  
    parameter "Number of drone agents" var: nb_drones category: "Drones" ;
    parameter "minimal speed" var: min_speed category: "Drones" min: 20 #km/#h ;
    parameter "maximal speed" var: max_speed category: "Drones" max: 30 #km/#h;
    
    output {
    display city_display type: opengl {
        species building aspect: base ;
        species road aspect: base ;
        species drones aspect: base ;
    }
     display chart_display refresh: every(10#cycles) { 
		//        chart "Road Status" type: series size: {1, 0.5} position: {0, 0} {
		//        data "Mean road destruction" value: mean (road collect each.destruction_coeff) style: line color: #green ;
		//        data "Max road destruction" value: road max_of each.destruction_coeff style: line color: #red ;
		//        }
        chart "People" type: histogram  style: exploded size: {1, 0.5} position: {0, 0}{
        data "Working" value: drones count (each.objective="working") color: #magenta;
        data "Resting" value: drones count (each.objective="resting") color: #blue;
        }
    }
    }
}