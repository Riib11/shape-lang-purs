module Language.Shape.Stlc.Recursor.Metacontext where

import Language.Shape.Stlc.Metacontext
import Language.Shape.Stlc.Syntax
import Prelude
import Prim hiding (Type)
import Prim.Row
import Record
import Control.Monad.State (State, modify_)
import Data.List (List)
import Data.List.Unsafe (index')
import Data.Newtype (unwrap)
import Data.OrderedSet (OrderedSet)
import Data.OrderedSet as OrderedSet
import Data.Traversable (sequence)
import Language.Shape.Stlc.Recursor.Index as Rec
import Language.Shape.Stlc.Recursor.Record (modifyHetero)
import Prim as Prim
import Type.Proxy (Proxy(..))
import Undefined (undefined)

-- | ProtoRec
type ProtoArgs r1 r2
  = ( argsMeta :: Record ( meta :: Metacontext | r1 ) | r2 )

-- | The `State (OrderedSet HoleId)` gathers the HoleIds of `HoleTypes` in the 
-- | program, statefully.
type ProtoRec args r a
  = Rec.ProtoRec args r (State (OrderedSet HoleId) a)

_argsMeta = Proxy :: Proxy "argsMeta"

_meta = Proxy :: Proxy "meta"

-- | recType
type ProtoArgsType r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsType r
  = Rec.ArgsType (ProtoArgsType () r)

type ArgsArrowType r
  = Rec.ArgsArrowType (ProtoArgsType ( dom::Metacontext, cod :: Metacontext ) r)

type ArgsDataType r
  = Rec.ArgsDataType (ProtoArgsType () r)

type ArgsHoleType r
  = Rec.ArgsHoleType (ProtoArgsType () r)

recType ::
  forall r a.
  Lacks "syn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  Lacks "argsMeta" r =>
  { arrow :: ProtoRec ArgsArrowType r a, data_ :: ProtoRec ArgsDataType r a, hole :: ProtoRec ArgsHoleType r a } ->
  ProtoRec ArgsType r a
recType rec =
  Rec.recType
    { arrow:
        \args@{ argsMeta: { meta } } ->
          rec.arrow
            $ modifyHetero _argsMeta (union { dom: meta, cod: incrementIndentation meta }) args
    , data_: rec.data_
    , hole:
        \args@{ syn: { hole } } -> do
          modify_ $ OrderedSet.insert hole.holeId
          rec.hole args
    }

-- -- | recTerm
type ProtoArgsTerm r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsTerm r
  = Rec.ArgsTerm (ProtoArgsTerm () r)

type ArgsLam r
  = Rec.ArgsLam (ProtoArgsTerm ( body :: Metacontext ) r)

type ArgsNeu r
  = Rec.ArgsNeu (ProtoArgsTerm ( args :: List Metacontext ) r)

type ArgsLet r
  = Rec.ArgsLet (ProtoArgsTerm ( type :: Metacontext, term :: Metacontext, body :: Metacontext ) r)

type ArgsBuf r
  = Rec.ArgsBuf (ProtoArgsTerm ( term :: Metacontext, body :: Metacontext ) r)

type ArgsData r
  = Rec.ArgsData (ProtoArgsTerm ( sum :: Metacontext, body :: Metacontext ) r)

type ArgsMatch r
  = Rec.ArgsMatch (ProtoArgsTerm ( term :: Metacontext, cases :: Metacontext ) r)

type ArgsHole r
  = Rec.ArgsHole (ProtoArgsTerm () r)

recTerm ::
  forall r a.
  Lacks "syn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  Lacks "argsMeta" r =>
  { lam :: ProtoRec ArgsLam r a, neu :: ProtoRec ArgsNeu r a, let_ :: ProtoRec ArgsLet r a, buf :: ProtoRec ArgsBuf r a, data_ :: ProtoRec ArgsData r a, match :: ProtoRec ArgsMatch r a, hole :: ProtoRec ArgsHole r a } ->
  ProtoRec ArgsTerm r a
recTerm rec =
  Rec.recTerm
    { lam:
        \args@{ syn: { lam }, argsMeta: { meta } } ->
          rec.lam
            $ modifyHetero _argsMeta
                (union { body: insertVarName lam.termBind.termId (unwrap lam.meta).name meta })
                args
    , neu:
        \args@{ syn: { neu }, argsMeta: { meta } } ->
          rec.neu
            $ modifyHetero _argsMeta
                (union { args: map (\_ -> incrementIndentation meta) neu.argItems })
                args
    , let_:
        \args@{ syn: { let_ }, argsMeta: { meta } } ->
          rec.let_
            $ modifyHetero _argsMeta
                ( let
                    meta' = incrementIndentation meta
                  in
                    union
                      { type: meta'
                      , term: meta'
                      , body: insertVarName let_.termBind.termId (unwrap let_.meta).name meta'
                      }
                )
                args
    , buf:
        \args@{ argsMeta: { meta } } ->
          rec.buf
            $ modifyHetero _argsMeta
                ( let
                    meta' = incrementIndentation meta
                  in
                    union
                      { term: meta'
                      , body: meta'
                      }
                )
                args
    , data_:
        \args@{ syn: { data_ }, argsMeta: { meta } } ->
          rec.data_
            $ modifyHetero _argsMeta
                ( let
                    meta' = incrementIndentation meta
                  in
                    union
                      { sum: meta'
                      , body: insertDataName data_.typeBind.typeId (unwrap data_.meta).name meta'
                      }
                )
                args
    , match:
        \args@{ argsMeta: { meta } } ->
          rec.match
            $ modifyHetero _argsMeta
                ( let
                    meta' = incrementIndentation meta
                  in
                    union
                      { term: meta'
                      , cases: meta'
                      }
                )
                args
    , hole: \args -> rec.hole args
    }

-- -- | recArgItems
-- type ProtoArgsArgItems r1 r2
--   = ProtoArgs r1 r2
-- type ArgsArgItems r
--   = Rec.ArgsArgItems (ProtoArgsArgItems () r)
-- type ArgsArgItemsCons r
--   = Rec.ArgsArgItemsCons (ProtoArgsArgItems () r)
-- type ArgsArgItemsNil r
--   = Rec.ArgsArgItemsNil (ProtoArgsArgItems () r)
-- recArgItems ::
--   forall r a.
--   Lacks "syn" r =>
--   Lacks "argsCtx" r =>
--   Lacks "argsIx" r =>
--   Lacks "argsMeta" r =>
--   { cons :: ProtoRec ArgsArgItemsCons r a, nil :: ProtoRec ArgsArgItemsNil r a } ->
--   ProtoRec ArgsArgItems r a
-- recArgItems rec =
--   Rec.recArgItems
--     { cons: rec.cons
--     , nil: rec.nil
--     }
type ProtoArgsArgItems r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsArgItems r
  = Rec.ArgsArgItems (ProtoArgsArgItems () r)

type ArgsArgItem r
  = Rec.ArgsArgItem (ProtoArgsArgItems () r)

recArgItems ::
  forall r a.
  Lacks "syn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  Lacks "argsMeta" r =>
  { argItem :: ProtoRec ArgsArgItem r a } ->
  ProtoRec ArgsArgItems r (List a)
recArgItems rec = sequence <<< Rec.recArgItems rec

-- | recCaseItem
type ProtoArgsCaseItems r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsCaseItems r
  = Rec.ArgsCaseItems (ProtoArgsCaseItems () r)

type ArgsCaseItem r
  = Rec.ArgsCaseItem (ProtoArgsCaseItems ( body :: Metacontext ) r)

recCaseItems ::
  forall r a.
  Lacks "syn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  Lacks "argsMeta" r =>
  { caseItem :: ProtoRec ArgsCaseItem r a } ->
  ProtoRec ArgsCaseItems r (List a)
recCaseItems rec = sequence <<< Rec.recCaseItems { caseItem: \args@{ argsMeta } -> rec.caseItem $ modifyHetero _argsMeta (union { body: incrementIndentation argsMeta.meta }) args }

-- | recSumItems
type ProtoArgsSumItems r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsSumItems r
  = Rec.ArgsSumItems (ProtoArgsSumItems () r)

type ArgsSumItem r
  = Rec.ArgsSumItem (ProtoArgsSumItems ( sumItem :: Metacontext, paramItems :: Metacontext ) r)

recSumItems ::
  forall r a.
  Lacks "syn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  Lacks "argsMeta" r =>
  { sumItem :: ProtoRec ArgsSumItem r a } ->
  ProtoRec ArgsSumItems r (List a)
recSumItems rec = sequence <<< Rec.recSumItems { sumItem: \args@{ argsMeta } -> let meta = incrementIndentation argsMeta.meta in rec.sumItem $ modifyHetero _argsMeta (union { sumItem: meta, paramItems: meta }) args }

-- | recParamItems
type ProtoArgsParamItems r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsParamItems r
  = Rec.ArgsParamItems (ProtoArgsParamItems () r)

type ArgsParamItem r
  = Rec.ArgsParamItem (ProtoArgsParamItems ( paramItem :: Metacontext, type_ :: Metacontext ) r)

recParamItems ::
  forall r a.
  Lacks "syn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  Lacks "argsMeta" r =>
  { paramItem :: ProtoRec ArgsParamItem r a } ->
  ProtoRec ArgsParamItems r (List a)
recParamItems rec = sequence <<< Rec.recParamItems { paramItem: \args@{ argsMeta: { meta } } -> rec.paramItem $ modifyHetero _argsMeta (union { paramItem: meta, type_: meta }) args }

-- | recTermBindItems
type ProtoArgsTermBindItems r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsTermBindItems r
  = Rec.ArgsTermBindItems (ProtoArgsTermBindItems () r)

type ArgsTermBindItem r
  = Rec.ArgsTermBindItem (ProtoArgsTermBindItems () r)

recTermBindItems ::
  forall r a.
  Lacks "syn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  Lacks "argsMeta" r =>
  { termBindItem :: ProtoRec ArgsTermBindItem r a } ->
  ProtoRec ArgsTermBindItems r (List a)
recTermBindItems rec = sequence <<< Rec.recTermBindItems rec

-- | recTermBind
type ArgsTermBind r
  = Rec.ArgsTermBind (ProtoArgs () r)

recTermBind ::
  forall r a.
  Lacks "syn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  Lacks "argMeta" r =>
  { termBind :: ProtoRec ArgsTermBind r a } ->
  ProtoRec ArgsTermBind r a
recTermBind rec = Rec.recTermBind { termBind: rec.termBind }

-- | recTypeBind
type ArgsTypeBind r
  = Rec.ArgsTypeBind (ProtoArgs () r)

recTypeBind ::
  forall r a.
  Lacks "syn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  Lacks "argsMeta" r =>
  { typeBind :: ProtoRec ArgsTypeBind r a } ->
  ProtoRec ArgsTypeBind r a
recTypeBind rec = Rec.recTypeBind { typeBind: rec.typeBind }
