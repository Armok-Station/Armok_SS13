# SYNTAX
Here are all the rules you must follow when writing code. It's important to note that large parts of the codebase do not consistently follow these rules, but this does not free you of the requirement to follow them.

## All BYOND paths must contain the full path
(i.e. absolute pathing)

DM will allow you nest almost any type keyword into a block, such as:

```DM
// Not our style!
datum
	datum1
		var
			varname1 = 1
			varname2
			static
				varname3
				varname4
		proc
			proc1()
				code
			proc2()
				code

		datum2
			varname1 = 0
			proc
				proc3()
					code
			proc2()
				. = ..()
				code
```

The use of this is not allowed in this project as it makes finding definitions via full text searching next to impossible. The only exception is the variables of an object may be nested to the object, but must not nest further.

The previous code made compliant:

```DM
// Matches /tg/station style.
/datum/datum1
	var/varname1
	var/varname2
	var/static/varname3
	var/static/varname4

/datum/datum1/proc/proc1()
	code
/datum/datum1/proc/proc2()
	code
/datum/datum1/datum2
	varname1 = 0
/datum/datum1/datum2/proc/proc3()
	code
/datum/datum1/datum2/proc2()
	. = ..()
	code
```

## Type paths must begin with a `/`
eg: `/datum/thing`, not `datum/thing`

## Type paths must be snake case
eg: `/datum/blue_bird`, not `/datum/BLUEBIRD` or `/datum/BlueBird` or `/datum/Bluebird` or `/datum/blueBird`

## Datum type paths must began with "datum"
In DM, this is optional, but omitting it makes finding definitions harder.


## Tabs, not spaces
You must use tabs to indent your code, NOT SPACES.

Do not use tabs/spaces for indentation in the middle of a code line. Not only is this inconsistent because the size of a tab is undefined, but it means that, should the line you're aligning to change size at all, we have to adjust a ton of other code. Plus, it often time hurts readability.

```dm
// Bad
#define SPECIES_MOTH			"moth"
#define SPECIES_LIZARDMAN		"lizardman"
#define SPECIES_FELINID			"felinid"

// Good
#define SPECIES_MOTH "moth"
#define SPECIES_LIZARDMAN "lizardman"
#define SPECIES_FELINID "felinid"
```

## Control statements
(if, while, for, etc)

* No control statement may contain code on the same line as the statement (`if (blah) return`)
* All control statements comparing a variable to a number should use the formula of `thing` `operator` `number`, not the reverse (eg: `if (count <= 10)` not `if (10 >= count)`)

## Operators
### Spacing
* Operators that should be separated by spaces
	* Boolean and logic operators like &&, || <, >, ==, etc (but not !)
	* Bitwise AND &
	* Argument separator operators like , (and ; when used in a forloop)
	* Assignment operators like = or += or the like
* Operators that should not be separated by spaces
	* Bitwise OR |
	* Access operators like . and :
	* Parentheses ()
	* logical not !

Math operators like +, -, /, *, etc are up in the air, just choose which version looks more readable.

### Use
* Bitwise AND - '&'
	* Should be written as `variable & CONSTANT` NEVER `CONSTANT & variable`. Both are valid, but the latter is confusing and nonstandard.
* Associated lists declarations must have their key value quoted if it's a string
	* WRONG: `list(a = "b")`
	* RIGHT: `list("a" = "b")`

## Use static instead of global
DM has a var keyword, called global. This var keyword is for vars inside of types. For instance:

```DM
/mob
	var/global/thing = TRUE
```
This does NOT mean that you can access it everywhere like a global var. Instead, it means that that var will only exist once for all instances of its type, in this case that var will only exist once for all mobs - it's shared across everything in its type. (Much more like the keyword `static` in other languages like PHP/C++/C#/Java)

Isn't that confusing?

There is also an undocumented keyword called `static` that has the same behaviour as global but more correctly describes BYOND's behaviour. Therefore, we always use static instead of global where we need it, as it reduces suprise when reading BYOND code.

## Naming variables
### Use `var/name` format when declaring variables
While DM allows other ways of declaring variables, this one should be used for consistency.

### Use descriptive and obvious names
Optimize for readability, not writability. While it is certainly easier to write `M` than `victim`, it will cause issues down the line for other developers to figure out what exactly your code is doing, even if you think the variable's purpose is obvious.

### Don't use abbreviations
Avoid variables like C, M, and H. Prefer names like "user", "victim", "weapon", etc.

```dm
// What is M? The user? The target?
// What is A? The target? The item?
/proc/use_item(mob/M, atom/A)

// Much better!
/proc/use_item(mob/user, atom/target)
```

Unless it is otherwise obvious, try to avoid just extending variables like "C" to "carbon"--this is slightly more helpful, but does not describe the *context* of the use of the variable.

### Naming things when typecasting
When typecasting, keep your names descriptive:
```dm
var/mob/living/living_target = target
var/mob/living/carbon/carbon_target = living_target
```

Of course, if you have a variable name that better describes the situation when typecasting, feel free to use it.

Note that it's okay, semantically, to use the same variable name as the type, e.g.:
```dm
var/atom/atom
var/client/client
var/mob/mob
```

Your editor may highlight the variable names, but BYOND, and we, accept these as variable names:

```dm
// This functions properly!
var/client/client = CLIENT_FROM_VAR(usr)
// vvv this may be highlighted, but it's fine!
client << browse(...)
```

### Name things as directly as possible
`was_called` is better than `has_been_called`. `notify` is better than `do_notification`.

### Avoid negative variable names
`is_flying` is better than `is_not_flying`. `late` is better than `not_on_time`.
This prevents double-negatives (such as `if (!is_not_flying)` which can make complex checks more difficult to parse.

### Exceptions to variable names

Exceptions can be made in the case of inheriting existing procs, as it makes it so you can use named parameters, but *new* variable names must follow these standards. It is also welcome, and encouraged, to refactor existing procs to use clearer variable names.

Naming numeral iterator variables `i` is also allowed, but do remember to [Avoid unnecessary type checks and obscuring nulls in lists](./STANDARDS.md#avoid-unnecessary-type-checks-and-obscuring-nulls-in-lists), and making more descriptive variables is always encouraged.

```dm
// Bad
for (var/datum/reagent/R as anything in reagents)

// Good
for (var/datum/reagent/deadly_reagent as anything in reagents)

// Allowed, but still has the potential to not be clear. What does `i` refer to?
for (var/i in 1 to 12)

// Better
for (var/month in 1 to 12)

// Bad, only use `i` for numeral loops
for (var/i in reagents)
```

## Things that do not matter
The following coding styles are not only not enforced at all, but are generally frowned upon to change for little to no reason:

* English/British spelling on var/proc names
	* Color/Colour - both are fine, but keep in mind that BYOND uses `color` as a base variable
* Spaces after control statements
	* `if()` and `if ()` - nobody cares!
