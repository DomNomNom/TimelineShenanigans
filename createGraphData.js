/*

This file turns the existing data structure into something more suitable

classes:
    Momemnt
    Character
    Link
    Attributes

relations: (JSON)
    Link has keys for 2 Characters: source and target
    Character has key for one Moment
    Character has key for attributes

Generated relations:
    moment has a list of characters
    Characters have a list of links:     links where we are the source
    characters have a list of backlinks: links where we are the target
*/
