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
	int nbTurtle <- 20000;
	float propInfectedInit <- 0.01;
	int gridSize <- 300;
	
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
	
	init {
		create turtle number: nbTurtle {
			// Attribution of own t private parameter
			te <- int(ceil(lognormal_rnd(0, globalTe))); // Need to ensure 0 is the correct μ
			ti <- int(ceil(lognormal_rnd(0, globalTi))); // En vrai ça fait une variabilité monstre sur les sorties, ça. On est sûrs que c'est la fonction qu'on veut?
			tr <- int(ceil((lognormal_rnd(0, globalTr)))); // D'ailleurs, ça donne souvent des trucs entre 0 et 1. Comme il y a minimum un step pour qu'il register le passage au nouveau state, je l'ai ceilingué.
		}
		
		// Initialise initialy infected agents
		ask int(floor(propInfectedInit * nbTurtle)) among turtle {
			self.state <- "infected";
			self.myColour <- #green;
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
	reflex endSim when: time >= endStep {
		endSimu <- true;
		do pause;
	}
	
}

grid worldGrid width: gridSize height: gridSize neighbors: 8 {
	bool steppedOnByInfected <- false;
//	reflex clean { Ca ne marchait pas de le mettre dans move?
//		steppedOnByInfected <- false;
//	}
}

species turtle control: fsm parallel: true {
	
	// Parameters
	int te;
	int ti;
	int tr;
	
	// Variables
	int infectionTimer <- 0;
	rgb myColour <- #blue;
	worldGrid myCell;
	list<worldGrid> infectionCells <- [myCell];
	
	init {
		myCell <- one_of(worldGrid);
		location <- myCell.location;
	}
	
	// FSM states
	state susceptible initial: true {
		
		enter {
			infectionCells <- [myCell];
		}
		
		infectionCells <<+ myCell.neighbors;
		infectionCells <- infectionCells where each.steppedOnByInfected; // TODO c'est un chouette moyen de réduire le calcule mais ça marche pas. Certain de ça? Je pense que c'est corrigé, là, non?
//		infectionCells <- infectionCells collect(each with:(steppedOnByInfected = true));
		
//		list nbNeig <- infectionCells accumulate (turtle overlapping each); 
		int nbNeighInfectedTurtles <- length(infectionCells);
		transition to: exposed when: (nbNeighInfectedTurtles > 0) and (rnd(1000) / 1000 < 1 - exp( - infectionRate * nbNeighInfectedTurtles)) {
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
			myColour <- #blue;
		}
		
	}
	
	reflex updateInfectionTimer when: state != "susceptible"{
//		write state + self + "+1";
		infectionTimer <- infectionTimer + 1;
	}
	
	// Movement mechanic
	reflex move {
		myCell.steppedOnByInfected <- false;
		myCell <- one_of (worldGrid);
		location <- myCell.location;
		myCell.steppedOnByInfected <- state = "infected" ? true : false;
		//write  "le nombre de cellule infecté  le nombre de tutle infecté ? " + (worldGrid count(each.steppedOnByInfected = true)) = (turtle count(each.state = "infected" ));
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

experiment batchRun autorun: true type: batch repeat: nbReplications until: endSimu {
	
	parameter "Proportion of initially infected individuals" var: propInfectedInit <- 0.1 min: 0.0 max: 1.0;
	
	reflex saveResults {
		ask simulations {
//			save [time, propSusceptible, propExposed, propInfected, propRecovered] to: "SSCrisis.csv" format: "csv" rewrite: (int(self) = 0) ? true : false header: true;
		}
	}
}




