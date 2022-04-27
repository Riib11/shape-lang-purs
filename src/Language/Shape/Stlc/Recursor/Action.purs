module Language.Shape.Stlc.Recursor.Action where

import Language.Shape.Stlc.Types
import Prelude
import Prim.Row
import Data.Maybe (Maybe(..))
import Language.Shape.Stlc.Index (IxDown(..), IxUp(..))
import Language.Shape.Stlc.Key (keys)
import Language.Shape.Stlc.Recursor.Index as Rec
import Language.Shape.Stlc.Recursor.Record (modifyHetero)
import Record (set)
import Type.Proxy (Proxy(..))
import Undefined (undefined)

-- | ProtoRec
type ProtoArgs r1 r2
  = ( argsAct :: Record ( actions :: Actions | r1 ) | r2 )

type ProtoRec args r a
  = Rec.ProtoRec args r a

_argsAct = Proxy :: Proxy "argsAct"

_actions = Proxy :: Proxy "actions"

-- | recType
type ProtoArgsType r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsType r
  = Rec.ArgsType (ProtoArgsType () r)

type ArgsArrowType r
  = Rec.ArgsArrowType (ProtoArgsType () r)

type ArgsDataType r
  = Rec.ArgsDataType (ProtoArgsType () r)

type ArgsHoleType r
  = Rec.ArgsHoleType (ProtoArgsType () r)

recType ::
  forall r a.
  Lacks "argsSyn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsMeta" r =>
  Lacks "argsIx" r =>
  Lacks "argsAct" r =>
  { arrow :: ProtoRec ArgsArrowType r a, data_ :: ProtoRec ArgsDataType r a, hole :: ProtoRec ArgsHoleType r a } ->
  ProtoRec ArgsType r a
recType rec =
  Rec.recType
    { arrow:
        \args ->
          rec.arrow
            $ modifyHetero _argsAct
                ( set _actions
                    $ [ Action
                          { label: Just "delete"
                          , triggers: [ ActionTrigger_Keypress { keys: keys.delete } ]
                          , effect: undefined
                          }
                      ]
                    <> common args
                )
                args
    , data_:
        \args ->
          rec.data_
            $ modifyHetero _argsAct
                ( set _actions
                    $ []
                    <> common args
                )
                args
    , hole:
        \args ->
          rec.hole
            $ modifyHetero _argsAct
                ( set _actions
                    $ []
                    <> common args
                )
                args
    }
  where
  common :: forall r1 r2. Record (Rec.ProtoArgsType r1 r2) -> Actions
  common args =
    [ Action
        { label: Just "dig"
        , triggers: [ ActionTrigger_Keypress { keys: keys.dig } ]
        , effect: undefined
        }
    , Action
        { label: Just "enarrow"
        , triggers: [ ActionTrigger_Keypress { keys: keys.lambda } ]
        , effect: undefined
        }
    , Action
        { label: Just "copy"
        , triggers: [ ActionTrigger_Keypress { keys: keys.copy } ]
        , effect: undefined
        }
    , toggleIndentation_Action args.argsIx.visit.ix
    ]

-- | recTerm
type ProtoArgsTerm r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsTerm r
  = Rec.ArgsTerm (ProtoArgsTerm () r)

type ArgsLam r
  = Rec.ArgsLam (ProtoArgsTerm () r)

type ArgsNeu r
  = Rec.ArgsNeu (ProtoArgsTerm () r)

type ArgsLet r
  = Rec.ArgsLet (ProtoArgsTerm () r)

type ArgsBuf r
  = Rec.ArgsBuf (ProtoArgsTerm () r)

type ArgsData r
  = Rec.ArgsData (ProtoArgsTerm () r)

type ArgsMatch r
  = Rec.ArgsMatch (ProtoArgsTerm () r)

type ArgsHole r
  = Rec.ArgsHole (ProtoArgsTerm () r)

recTerm ::
  forall r a.
  Lacks "argsSyn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsMeta" r =>
  Lacks "argsIx" r =>
  Lacks "argsAct" r =>
  { lam :: ProtoRec ArgsLam r a, neu :: ProtoRec ArgsNeu r a, let_ :: ProtoRec ArgsLet r a, buf :: ProtoRec ArgsBuf r a, data_ :: ProtoRec ArgsData r a, match :: ProtoRec ArgsMatch r a, hole :: ProtoRec ArgsHole r a } ->
  ProtoRec ArgsTerm r a
recTerm rec =
  Rec.recTerm
    { lam:
        \args ->
          rec.lam
            $ modifyHetero _argsAct
                ( set _actions
                    $ [ Action
                          { label: Just "unlambda"
                          , triggers: [ ActionTrigger_Keypress { keys: keys.unlambda } ]
                          , effect: undefined
                          }
                      , Action
                          { label: Just "uneta"
                          , triggers: [ ActionTrigger_Keypress { keys: keys.uneta } ]
                          , effect: undefined
                          }
                      ]
                    <> common args
                )
                args
    , neu:
        \args ->
          rec.neu
            $ modifyHetero _argsAct
                ( set _actions
                    $ [ Action
                          { label: Just "eta"
                          , triggers: [ ActionTrigger_Keypress { keys: keys.eta } ]
                          , effect: undefined
                          }
                      ]
                    <> common args
                )
                args
    , let_:
        \args ->
          rec.let_
            $ modifyHetero _argsAct
                ( set _actions
                    $ [ Action
                          { label: Just "unlet"
                          , triggers: [ ActionTrigger_Keypress { keys: keys.unlet } ]
                          , effect: undefined
                          }
                      ]
                    <> common args
                )
                args
    , buf:
        \args ->
          rec.buf
            $ modifyHetero _argsAct
                ( set _actions
                    $ [ Action
                          { label: Just "unbuf"
                          , triggers: [ ActionTrigger_Keypress { keys: keys.unbuf } ]
                          , effect: undefined
                          }
                      ]
                    <> common args
                )
                args
    , data_:
        \args ->
          rec.data_
            $ modifyHetero _argsAct
                ( set _actions
                    $ [ Action
                          { label: Just "undata"
                          , triggers: [ ActionTrigger_Keypress { keys: keys.undata } ]
                          , effect: undefined
                          }
                      ]
                    <> common args
                )
                args
    , match:
        \args ->
          rec.match
            $ modifyHetero _argsAct
                ( set _actions
                    $ []
                    <> common args
                )
                args
    , hole:
        \args ->
          rec.hole
            $ modifyHetero _argsAct
                ( set _actions
                    $ [ Action
                          { label: Just "fill"
                          , triggers: [] -- TODO
                          , effect: undefined
                          }
                      ]
                    <> common args
                )
                args
    }
  where
  common :: forall r1 r2. Record (Rec.ProtoArgsTerm r1 r2) -> Actions
  common args =
    [ Action
        { label: Just "dig"
        , triggers: [ ActionTrigger_Keypress { keys: keys.dig } ]
        , effect: undefined
        }
    , Action
        { label: Just "enlambda"
        , triggers: [ ActionTrigger_Keypress { keys: keys.lambda } ]
        , effect: undefined
        }
    , Action
        { label: Just "enlet"
        , triggers: [ ActionTrigger_Keypress { keys: keys.let_ } ]
        , effect: undefined
        }
    , Action
        { label: Just "endata"
        , triggers: [ ActionTrigger_Keypress { keys: keys.data_ } ]
        , effect: undefined
        }
    , Action
        { label: Just "enbuffer"
        , triggers: [ ActionTrigger_Keypress { keys: keys.buf } ]
        , effect: undefined
        }
    , Action
        { label: Just "copy"
        , triggers: [ ActionTrigger_Keypress { keys: keys.dig } ]
        , effect: undefined
        }
    , toggleIndentation_Action args.argsIx.visit.ix
    ]

-- | Generic Actions
toggleIndentation_Action :: IxUp -> Action
toggleIndentation_Action ixUp =
  Action
    { label: Just "toggle indentation"
    , triggers: [ ActionTrigger_Keypress { keys: keys.indent } ]
    , effect: undefined
    }
