/**
* Name: Main
* Author: AS
* Tags: 
*/


model Main

global torus: true {
	
	// Global parameters
	int nbReplications <- 30;
	int endStep <- 730;
	int mySeed <- rnd(200000);
	
	// create liste of values
	list simTime <- [];
	list S <- [];
	list E <- [];
	list I <- [];
	list R <- [];
	
	
	// Simulation parameters
	int nbTurtle <- 20000;
	float propInfectedInit <- 0.01;
	int gridSize <- 300 ;
	
	// Infection transition times
	int globalTe <- 3;
	int globalTi <- 7;
	int globalTr <- 365;
	
	float infectionRate <- 0.5; // ie Beta in SEIR models
	
	// Output variables
	float propInfected update: turtle count (each.state = "infected") / nbTurtle;
	float propSusceptible update: turtle count (each.state = "susceptible") / nbTurtle;
	float propExposed update: turtle count (each.state = "exposed") / nbTurtle;
	float propRecovered update: turtle count (each.state = "recovered") / nbTurtle;
	
	bool isBatch <- false;

	
	init {
		create turtle number: nbTurtle {
			// Attribution of own t private parameter
			te <- int(exp_rnd(globalTe)); // int(foat) eq. to flooring the float
			ti <- int(exp_rnd(globalTi));
			tr <- int(exp_rnd(globalTr));
		}
		
		// Initialise initialy infected agents
		ask int(floor(propInfectedInit * nbTurtle)) among turtle {
			self.state <- "infected";
			self.myColour <- #green;
			self.isSusceptible <- false;
			self.infectionTimer <- self.te;
		}
		
		// Initialise outputs
		propInfected <- turtle count (each.state = "infected") / length(turtle);
		propSusceptible <- turtle count (each.state = "susceptible") / length(turtle);
		propExposed <- turtle count (each.state = "exposed") / length(turtle);
		propRecovered <- turtle count (each.state = "recovered") / length(turtle);
		write "infected init " + turtle count (each.state = "infected");
		write "infected init " + turtle count (each.state = "infected") / length(turtle) ;
				
	}
	
	bool endSimu <- false; // Stops batches
	reflex createFinalList {
		add time to: simTime ;
		add propSusceptible to: S;
		add propExposed to: E;
		add propInfected to: I;
		add propRecovered to: R;
	}
	
	reflex saveResults when: isBatch {
		save [time, propSusceptible, propExposed, propInfected, propRecovered] to: "../results/SSCrisis"+ mySeed +".csv" 
			format: "csv" rewrite: (cycle = 0) ? true: false header: true;
	}
}

grid worldGrid width: gridSize height: gridSize neighbors: 8 {
	bool steppedOnByInfected <- false;
	list<turtle> myTurtles;
	
	reflex clean {
		steppedOnByInfected <- false;
	}
}

species turtle control: fsm /*parallel: true*/ {
	
	// Parameters
	int te;
	int ti;
	int tr;
	
	// Variables
	bool isSusceptible;
	int infectionTimer <- 0;
	rgb myColour <- #blue;
	worldGrid myCell <- one_of(worldGrid);
	
	init {
		location <- myCell.location;
		add self to: myCell.myTurtles ;
	}
	
//	aspect base {
//		draw circle(1) color: #yellow;
//	}
	// FSM states
	state susceptible initial: true {		
//		list<worldGrid> infectionCells <- [myCell];
//		infectionCells <<+ myCell.neighbors;
		list<worldGrid> infectionCells <- myCell.neighbors + myCell;
		//infectionCells <- infectionCells where each.steppedOnByInfected; // TODO c'est un chouette moyen de réduire le calcule mais ça marche pas
		//infectionCells <- infectionCells collect(each with:(steppedOnByInfected = true));
		
		list<turtle> neigh <- infectionCells accumulate (each.myTurtles); 
		list<turtle> neigInfected <- neigh where(each.state = "infected");
		int nbNeighInfectedTurtles <- length(neigInfected);
		transition to: exposed when: (nbNeighInfectedTurtles > 0) and (rnd(1000) / 1000 < 1 - exp( - infectionRate * nbNeighInfectedTurtles)) {
			isSusceptible <- false;
			infectionTimer <- 0;
			myColour <- #orange;
		}
	}
	
	state exposed {
		transition to: infected when: infectionTimer > te {
			infectionTimer <- 0;
			myColour <- #orange;
		}
	}
	
	state infected {
		ask myCell {
			steppedOnByInfected <- true;
			}
		transition to: recovered when: infectionTimer > ti {
			infectionTimer <- 0;
			myColour <- #red;
		}
	}
	
	state recovered {
		transition to: susceptible when: infectionTimer > tr {
			infectionTimer <- 0;
			isSusceptible <- true;
			myColour <- #blue;
		}
		
	}
	
	reflex updateInfectionTimer {
		infectionTimer <- infectionTimer + 1;
	}
	
	// Movement mechanic
	reflex move {
		//myCell.steppedOnByInfected <- false;
		remove self from: myCell.myTurtles ;
		myCell <- one_of (worldGrid);
		add self to: myCell.myTurtles ;
		myCell.steppedOnByInfected <- state = "infected" ? true : false;
		//write  "le nombre de cellule infecté  le nombre de tutle infecté ? " + (worldGrid count(each.steppedOnByInfected = true)) = (turtle count(each.state = "infected" ));
		location <- myCell.location;
	}
	
	// Visual aspect
	aspect default {
		draw square(0.5) color: myColour border: #black;
	}
	
}

experiment Run type: gui {
	parameter "Proportion of initially infected individuals" var: propInfectedInit <- 0.01 min: 0.0 max: 1.0;
	
	output {
		display mainDisp type: java2D {
			grid worldGrid border: #lightgrey;
			species turtle;
		}
		
		display plotDisp type: java2D {
			chart "SEIR outputs" type: series {
				data "Susceptible individuals proportion" value: propSusceptible color: #blue;
				data "Exposed individuals proportion" value: propExposed color: #orange;
				data "Infected individuals proportion" value: propInfected color: #green;
				data "Recovered individuals proportion" value: propRecovered color: #red;
			}
		}
	}
}

experiment batchRun autorun: true type: batch repeat: 30 until: time > 730 parallel: true {
	
	parameter "Proportion of initially infected individuals" var: propInfectedInit <- 0.1 ;
	parameter "mode batch" var: isBatch <- true;
	
	/*  reflex end_of_runs {
    int cpt <- 0;
        ask simulations {
            // save [time, propSusceptible, propExposed, propInfected, propRecovered] to: "../results/SSCrisis"+ cpt +".csv" 
			//	format: "csv" rewrite: (int(self) = 0) ? true : false header: true;
			save [simTime, S, E, I, R] to: "../results/SSCrisis"+ mySeed + "_" + cpt +".csv" 
				format: "csv" header: true;
            cpt <- cpt + 1;
        }
    }*/
}



