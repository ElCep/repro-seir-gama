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
	
	// Simulation parameters
	int nbTurtle <- 200;
	float propInfectedInit;
	
	// Random exponentielle
	int globalTe <- 3;
	int globalTi <- 7;
	int globalTr <- 365;
	
	float infectionRate <- 0.5; // ie Beta in SEIR models
	
	// Output variables
	float propInfected update: turtle count (each.state = "infected") / nbTurtle;
	float propSusceptible update: turtle count (each.state = "susceptible") / nbTurtle;
	float propExposed update: turtle count (each.state = "exposed") / nbTurtle;
	float propRecovered update: turtle count (each.state = "recovered") / nbTurtle;
	
	init {
		create turtle number: nbTurtle {
			// Attribution of own t private parameter
			te <- int( - globalTe * ln (rnd (1.0))); // int(f) eq. to flooring the float f
			ti <- int( - globalTi * ln (rnd (1.0)));
			tr <- int( - globalTr * ln (rnd (1.0)));
		}
		
		// Initialise initialy exposed agents
		ask int(floor(propInfectedInit * nbTurtle)) among turtle {
			self.state <- "exposed";
			self.myColour <- #orange;
		}
		
		// Initialise outputs
		propInfected <- turtle count (each.state = "infected") / length(turtle);
		propSusceptible <- turtle count (each.state = "susceptible") / length(turtle);
		propExposed <- turtle count (each.state = "exposed") / length(turtle);
		propRecovered <- turtle count (each.state = "recovered") / length(turtle);
		
	}
	
	bool endSimu <- false; // Stops batches
	reflex endSim when: time >= endStep {
		endSimu <- true;
		do pause;
	}
	
}

grid worldGrid width: 30 height: 30 neighbors: 8 {
	bool steppedOn <- false;
}

species turtle control: fsm parallel: true {
	
	// Parameters
	int te;
	int ti;
	int tr;
	
	// Variables
	bool isSusceptible;
	int infectionTimer;
	rgb myColour <- #blue;
	worldGrid myCell <- one_of(worldGrid);
	
	init {
		location <- myCell.location;
	}
	
	// FSM states
	state susceptible initial: true {
		enter {
			isSusceptible <- true;
			myColour <- #blue;
		}
		
		list<worldGrid> infectionCells <- [myCell];
		infectionCells <<+ myCell.neighbors;
		
		int nbNeighInfectedTurtles <- 0;
		ask infectionCells where each.steppedOn {
			nbNeighInfectedTurtles <- nbNeighInfectedTurtles + ((turtle overlapping self) count (each.state = "infected"));
		}
		
		transition to: exposed when: (nbNeighInfectedTurtles > 0) and (rnd(1000) / 1000 < 1 - exp( - infectionRate * nbNeighInfectedTurtles)) {
			write "" + self + " got infected";
			infectionTimer <- 0;
			isSusceptible <- false;
			myColour <- #orange;
		}
	}
	
	state exposed {
		transition to: infected when: infectionTimer > te {
			myColour <- #green;
		}
	}
	
	state infected {
		transition to: recovered when: infectionTimer > te + ti {
			myColour <- #red;
		}
	}
	
	state recovered {
		transition to: susceptible when: infectionTimer > te + ti + tr;
		
	}
	
	reflex updateInfectionTimer when: !isSusceptible {
		infectionTimer <- infectionTimer + 1;
	}
	
	// Movement mechanic
	reflex move {
		myCell.steppedOn <- false;
		myCell <- one_of (myCell.neighbors);
		myCell.steppedOn <- true;
		location <- myCell.location;
	}
	
	// Visual aspect
	aspect default {
		draw square(0.3) color: myColour border: #black;
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

experiment batchRun autorun: true type: batch repeat: nbReplications until: endSimu {
	
	parameter "Proportion of initially infected individuals" var: propInfectedInit <- 0.001 min: 0.0 max: 1.0;
	
	reflex saveResults {
		ask simulations {
			save [time, propSusceptible, propExposed, propInfected, propRecovered] to: "SSCrisis.csv" format: "csv" rewrite: (int(self) = 0) ? true : false header: true;
		}
	}
}

// interface : proportions en graphe
// Paramètre: proportion de population infectée

// batch 30 réplications
// Sortie 30 graphes
// 1 csv 700 lignes (temps)
// colonnes : tps S E I R



