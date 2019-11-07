#define SOLID 			1
#define LIQUID			2
#define GAS				3

#define REAGENT_NORMAL_PH 7.000
#define REAGENT_PH_ACCURACY 0.001
#define REAGENT_PURITY_ACCURACY 0.001
#define DEFAULT_SPECIFIC_HEAT 200

#define INJECTABLE		(1<<0)	// Makes it possible to add reagents through droppers and syringes.
#define DRAWABLE		(1<<1)	// Makes it possible to remove reagents through syringes.

#define REFILLABLE		(1<<2)	// Makes it possible to add reagents through any reagent container.
#define DRAINABLE		(1<<3)	// Makes it possible to remove reagents through any reagent container.

#define TRANSPARENT		(1<<4)	// Used on containers which you want to be able to see the reagents off.
#define AMOUNT_VISIBLE	(1<<5)	// For non-transparent containers that still have the general amount of reagents in them visible.
#define NO_REACT        (1<<6)  // Applied to a reagent holder, the contents will not react with each other.

// Is an open container for all intents and purposes.
#define OPENCONTAINER 	(REFILLABLE | DRAINABLE | TRANSPARENT)


#define TOUCH			1	// splashing
#define INGEST			2	// ingestion
#define VAPOR			3	// foam, spray, blob attack
#define PATCH			4	// patches
#define INJECT			5	// injection


//defines passed through to the on_reagent_change proc
#define DEL_REAGENT		1	// reagent deleted (fully cleared)
#define ADD_REAGENT		2	// reagent added
#define REM_REAGENT		3	// reagent removed (may still exist)
#define CLEAR_REAGENTS	4	// all reagents were cleared
#define REACT_REAGENTS	5	// a reaction occured

#define MIMEDRINK_SILENCE_DURATION 30  //ends up being 60 seconds given 1 tick every 2 seconds
//used by chem masters and pill presses
#define PILL_STYLE_COUNT 22 //Update this if you add more pill icons or you die
#define RANDOM_PILL_STYLE 22 //Dont change this one though

//fermichem react bitflags
#define REAGENT_DEAD_PROCESS		(1<<0)	//calls on_mob_dead() if present in a dead body
#define REAGENT_DONOTSPLIT			(1<<1)	//Do not split the chem at all during processing
#define REAGENT_ONLYINVERSE			(1<<2)	//Only invert chem, no splitting
#define REAGENT_ONMOBMERGE			(1<<3)	//Call on_mob_life proc when reagents are merging.
#define REAGENT_INVISIBLE			(1<<4)	//Doesn't appear on handheld health analyzers.
#define REAGENT_FORCEONNEW			(1<<5)  //Forces a on_new() call without a data overhead
#define REAGENT_SNEAKYNAME			(1<<6)  //When inverted, the inverted chem uses the name of the original chem
#define REAGENT_SPLITRETAINVOL		(1<<7)  //Retains initial volume of chem when splitting

//Chemical reaction flags, for determining reaction specialties
#define REACTION_CLEAR_IMPURE       (1<<0)  //Convert into impure/pure on reaction completion
#define REACTION_CLEAR_INVERSE      (1<<1)  //Convert into inverse on reaction completion when purity is low enough

//reagent specific heats
#define SPECIFIC_HEAT_DEFAULT			200

#define SPECIFIC_HEAT_PLASMA			500
