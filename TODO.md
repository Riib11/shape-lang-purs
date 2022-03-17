# TODO

- Jacob
  - [x] decide how cases work in match
  - [ ] recursion principle with wrap (uses TypeChanges context)
  - [ ] change\*
    - [x] changeTerm
    - [x] changeType
    - [ ] changeDef
    - [ ] changeBlock
    - [ ] changeNeu
  - [x] changes syntax (curried)
  - [x] hole stuff (i.e. unification)

- Henry
  - [ ] syntax
    - [x] upgrade lists to have metadata for each item
  - [ ] recursors
    - [x] base
    - [x] context + type
    - [x] metacontext (for derived metadata stuff: names, shadows, constructor
          ids, etc)
    - [ ] index (still have to handle typechanges)
  - [ ] index
    - [x] upgrade syntax/metadata so that lists have an `*ItemMetadata` for each
          element of the list
    - [x] upgrade index so that each step has constant number of children (lists
          have 2 children: head, tail)
    - [x] upgrade index recursor layer
    - [x] upgrade renderer
  - [ ] rendering

    - [x] basic outline
    - [x] indentation
    - [x] shadowing
      - [x] bug: paramter names in types not shadowing correctly, but lambdas
            do??
    - [ ] actions
      - [ ] hovering over syntax will highlight the innermost syntax element
            (even if hovering over the whitespace between)
      - [ ] list manipulations
        - insertions: triggers is between list items
        - deletions: trigger is at list item
        - move: delete; insert
      - [ ] term holes
        - show type in hole
        - drag a term into hole
        - drag a var from lambda into hoel
        - paste into hole
        - basic fills:
          - neutral form (given a var in context)
            - checks all partial applications, and selects first viable
          - match (given term to match on)
          - lambda
      - [ ] lambda term
        - remove lambda around via RemoveArg typechange
      - [ ] term
        - dig
        - copy to clipboard
      - [ ] renaming
        - things that can be renamed: parameters, termBindings, typeBindings
        - pops up a dialogue box, _or_ edits in place via `<input>` or changing
          moves and handling keyboard input
    - [ ] cursor (worry about this after mouse actions work)
