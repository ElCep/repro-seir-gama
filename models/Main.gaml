/**
* Name: Main
* Based on the internal empty template. 
* Author: AS
* Tags: 
*/


model Main

global torus: true {
	// Paramètres
	int infectionRadius <- 1; // En nombre de cellules
	int nbTurtle <- 200;
	float propInfectedInit <- 0.1;
	int endStep <- 730;
	
	// Random exponentielle
	int globalTi <- 7;
	int globalTe <- 3;
	int globalTr <- 365;
	// - globalT * ln (rnd (1.0))
	
	float infectionRate <- 0.5; // beta dans les SEIR
	
	// Output variables
	float propInfected; // update 
	float propSuseptible;
	float propExposed;
	float propRecovered;
	
	init {
		create turtle number: nbTurtle;
//		ask int(floor(propInfectedInit * nbTurtle)) among: turtle {
//			// Change d'état en exposed
//		}
		// Proportion d'infectés à mettre
		// Emplacement random
	}
	
	
	reflex endSim when: time > endStep {
		do pause;
		// Réplication
	}
	
}

grid worldGrid width: 300 height: 300 neighbors: 8;

species turtle control: fsm {
	
	int ti;
	int te;
	int tr;
	float infectionTimer <- 0.0;
	
	state susceptible initial: true {
		// Couleur bleue
		// transition vers infecté quand à proximité d'infectés, avec une proba entre 0 et 1
		// tirée à chaque pas
		// if proba < (1 - exp( -beta * (count infected in radius))) alors je deviens exposed
		// Selon un radius
	}
	
	state exposed {
		enter {
			// faire tourner le timer
			// Devient orange
		}
		transition to: infected when: infectionTimer > te;
	}
	
	state infected {
			// Devient vert
		transition to: recovered when: infectionTimer > ti;
	}
	
	state recovered {
			// Devient rouge
		transition to: susceptible when: infectionTimer > tr;
		
	}
	
	reflex move {
		// choisis la cellule voisine à chaque step
	}
	
}

// interface : proportions en graphe
// Paramètre: proportion de population infectée

// batch 30 réplications
// Sortie 30 graphes
// 1 csv 700 lignes (temps)
// colonnes : tps SEIR



