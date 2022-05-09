module Language.Shape.Stlc.Recursor.Metacontext where

import Data.Foldable
import Language.Shape.Stlc.Metacontext
import Language.Shape.Stlc.Syntax
import Prelude
import Prim hiding (Type)
import Prim.Row
import Record
import Control.Monad.State (StateT)
import Control.Monad.State as State
import Data.List.Unsafe (List)
import Data.List.Unsafe as List
import Data.Newtype (unwrap)
import Data.Traversable (sequence)
import Debug as Debug
import Language.Shape.Stlc.Recursor.Index as Rec
import Language.Shape.Stlc.Recursor.Record (modifyHetero)
import Prim as Prim
import Type.Proxy (Proxy(..))
import Undefined (undefined)

-- | ProtoRec
type ProtoArgs r1 r2
  = ( meta :: Record ( meta :: Metacontext | r1 ) | r2 )

type ProtoRec args r a
  = Rec.ProtoRec args r a

_meta = Proxy :: Proxy "meta"

-- | recType
type ProtoArgsType r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsType r
  = Rec.ArgsType (ProtoArgsType () r)

type ArgsArrowType r
  = Rec.ArgsArrowType (ProtoArgsType ( dom :: Metacontext, cod :: Metacontext ) r)

type ArgsDataType r
  = Rec.ArgsDataType (ProtoArgsType () r)

type ArgsHoleType r
  = Rec.ArgsHoleType (ProtoArgsType () r)

recType ::
  forall r a.
  Lacks "syn" r =>
  Lacks "ctx" r =>
  Lacks "ix" r =>
  Lacks "meta" r =>
  { arrow :: ProtoRec ArgsArrowType r a, data_ :: ProtoRec ArgsDataType r a, hole :: ProtoRec ArgsHoleType r a } ->
  ProtoRec ArgsType r a
recType rec =
  Rec.recType
    { arrow:
        \args@{ meta: { meta } } ->
          rec.arrow
            $ modifyHetero _meta (union { dom: meta, cod: incrementIndentation meta }) args
    , data_: rec.data_
    , hole: rec.hole
    }

argsArrowType_dom :: forall r. Lacks "syn" r => Lacks "ctx" r => Lacks "ix" r => Lacks "meta" r => Record (ArgsArrowType r) -> Record (ArgsType r)
argsArrowType_dom = Rec.argsArrowType_dom >>> \args -> args { meta = { meta: args.meta.dom } }

argsArrowType_cod :: forall r. Lacks "syn" r => Lacks "ctx" r => Lacks "ix" r => Lacks "meta" r => Record (ArgsArrowType r) -> Record (ArgsType r)
argsArrowType_cod = Rec.argsArrowType_cod >>> \args -> args { meta = { meta: args.meta.cod } }

-- | recTerm
type ProtoArgsTerm r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsTerm r
  = Rec.ArgsTerm (ProtoArgsTerm () r)

type ArgsLam r
  = Rec.ArgsLam (ProtoArgsTerm ( termBind :: Metacontext, body :: Metacontext ) r)

type ArgsNeu r
  = Rec.ArgsNeu (ProtoArgsTerm ( argItems :: Metacontext ) r)

type ArgsLet r
  = Rec.ArgsLet (ProtoArgsTerm ( termBind :: Metacontext, type_ :: Metacontext, term :: Metacontext, body :: Metacontext ) r)

type ArgsBuf r
  = Rec.ArgsBuf (ProtoArgsTerm ( term :: Metacontext, body :: Metacontext ) r)

type ArgsData r
  = Rec.ArgsData (ProtoArgsTerm ( typeBind :: Metacontext, sumItems :: Metacontext, body :: Metacontext ) r)

type ArgsMatch r
  = Rec.ArgsMatch (ProtoArgsTerm ( term :: Metacontext, caseItems :: Metacontext ) r)

type ArgsHole r
  = Rec.ArgsHole (ProtoArgsTerm () r)

recTerm ::
  forall r a.
  Lacks "syn" r =>
  Lacks "ctx" r =>
  Lacks "ix" r =>
  Lacks "meta" r =>
  { lam :: ProtoRec ArgsLam r a, neu :: ProtoRec ArgsNeu r a, let_ :: ProtoRec ArgsLet r a, buf :: ProtoRec ArgsBuf r a, data_ :: ProtoRec ArgsData r a, match :: ProtoRec ArgsMatch r a, hole :: ProtoRec ArgsHole r a } ->
  ProtoRec ArgsTerm r a
recTerm rec =
  Rec.recTerm
    { lam:
        \args@{ syn: { lam }, meta: { meta } } ->
          let
            meta' = insertVar lam.termBind.termId (unwrap lam.meta).name meta
          in
            rec.lam
              $ modifyHetero _meta
                  (union { termBind: meta', body: meta' })
                  args
    , neu:
        \args@{ syn: { neu }, meta: { meta } } ->
          rec.neu
            $ modifyHetero _meta
                (union { argItems: meta })
                args
    , let_:
        \args@{ syn: { let_ }, meta: { meta } } ->
          rec.let_
            $ modifyHetero _meta
                ( let
                    meta' = incrementIndentation meta
                  in
                    union
                      { termBind: meta'
                      , type_: meta'
                      , term: meta'
                      , body: insertVar let_.termBind.termId (unwrap let_.meta).name meta'
                      }
                )
                args
    , buf:
        \args@{ meta: { meta } } ->
          rec.buf
            $ modifyHetero _meta
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
        \args@{ syn: { data_ }, meta: { meta } } ->
          rec.data_
            $ modifyHetero _meta
                ( let
                    meta' =
                      -- * note that the data type needs to be in the metacontext before the constructors, since the constructors refernce the data type in their type
                      List.foldl (\f sumItem -> f <<< insertVar sumItem.termBind.termId (unwrap sumItem.termBind.meta).name) identity data_.sumItems -- insert constructors into metacontext
                        <<< insertData data_ -- insert data into metacontext
                        $ incrementIndentation meta
                  in
                    union
                      { typeBind: meta'
                      , sumItems: meta'
                      , body: meta'
                      }
                )
                args
    , match:
        \args@{ meta: { meta } } ->
          rec.match
            $ modifyHetero _meta
                ( let
                    meta' = incrementIndentation meta
                  in
                    union
                      { term: meta'
                      , caseItems: meta'
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
--   Lacks "ctx" r =>
--   Lacks "ix" r =>
--   Lacks "meta" r =>
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
  Lacks "ctx" r =>
  Lacks "ix" r =>
  Lacks "meta" r =>
  { argItem :: ProtoRec ArgsArgItem r a } ->
  ProtoRec ArgsArgItems r (List a)
recArgItems rec = Rec.recArgItems rec

-- | recCaseItem
type ProtoArgsCaseItems r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsCaseItems r
  = Rec.ArgsCaseItems (ProtoArgsCaseItems () r)

type ArgsCaseItem r
  = Rec.ArgsCaseItem (ProtoArgsCaseItems ( termBindItems :: Metacontext, body :: Metacontext ) r)

recCaseItems ::
  forall r a.
  Lacks "syn" r =>
  Lacks "ctx" r =>
  Lacks "ix" r =>
  Lacks "meta" r =>
  { caseItem :: ProtoRec ArgsCaseItem r a } ->
  ProtoRec ArgsCaseItems r (List a)
recCaseItems rec =
  Rec.recCaseItems
    { caseItem:
        \args@{ meta } ->
          let
            meta' =
              foldl (\f termBindItem -> f <<< insertVar termBindItem.termBind.termId (unwrap termBindItem.termBind.meta).name) identity
                args.syn.caseItem.termBindItems
                $ incrementIndentation meta.meta
          in
            rec.caseItem $ modifyHetero _meta (union { termBindItems: meta', body: meta' }) args
    }

-- | recSumItems
type ProtoArgsSumItems r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsSumItems r
  = Rec.ArgsSumItems (ProtoArgsSumItems () r)

type ArgsSumItem r
  = Rec.ArgsSumItem (ProtoArgsSumItems ( sumItem :: Metacontext, termBind :: Metacontext, paramItems :: Metacontext ) r)

recSumItems ::
  forall r a.
  Lacks "syn" r =>
  Lacks "ctx" r =>
  Lacks "ix" r =>
  Lacks "meta" r =>
  { sumItem :: ProtoRec ArgsSumItem r a } ->
  ProtoRec ArgsSumItems r (List a)
recSumItems rec =
  Rec.recSumItems
    { sumItem:
        \args@{ meta } ->
          let
            meta' =
              insertVar args.syn.sumItem.termBind.termId (unwrap args.syn.sumItem.termBind.meta).name
                $ incrementIndentation meta.meta
          in
            rec.sumItem $ modifyHetero _meta (union { sumItem: meta', termBind: meta', paramItems: meta' }) args
    }

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
  Lacks "ctx" r =>
  Lacks "ix" r =>
  Lacks "meta" r =>
  { paramItem :: ProtoRec ArgsParamItem r a } ->
  ProtoRec ArgsParamItems r (List a)
recParamItems rec = Rec.recParamItems { paramItem: \args@{ meta: { meta } } -> rec.paramItem $ modifyHetero _meta (union { paramItem: meta, type_: meta }) args }

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
  Lacks "ctx" r =>
  Lacks "ix" r =>
  Lacks "meta" r =>
  { termBindItem :: ProtoRec ArgsTermBindItem r a } ->
  ProtoRec ArgsTermBindItems r (List a)
recTermBindItems rec = Rec.recTermBindItems rec

-- | recTermBind
type ArgsTermBind r
  = Rec.ArgsTermBind (ProtoArgs () r)

recTermBind ::
  forall r a.
  Lacks "syn" r =>
  Lacks "ctx" r =>
  Lacks "ix" r =>
  Lacks "meta" r =>
  { termBind :: ProtoRec ArgsTermBind r a } ->
  ProtoRec ArgsTermBind r a
recTermBind rec = Rec.recTermBind { termBind: rec.termBind }

-- | recTypeBind
type ArgsTypeBind r
  = Rec.ArgsTypeBind (ProtoArgs () r)

recTypeBind ::
  forall r a.
  Lacks "syn" r =>
  Lacks "ctx" r =>
  Lacks "ix" r =>
  Lacks "meta" r =>
  { typeBind :: ProtoRec ArgsTypeBind r a } ->
  ProtoRec ArgsTypeBind r a
recTypeBind rec = Rec.recTypeBind { typeBind: rec.typeBind }

-- | recTypeId
type ArgsTypeId r
  = Rec.ArgsTypeId (ProtoArgs () r)

recTypeId ::
  forall r a.
  Lacks "syn" r =>
  Lacks "ctx" r =>
  Lacks "ix" r =>
  Lacks "meta" r =>
  { typeId :: ProtoRec ArgsTypeId r a } ->
  ProtoRec ArgsTypeId r a
recTypeId = Rec.recTypeId

-- | recTermId
type ArgsTermId r
  = Rec.ArgsTermId (ProtoArgs () r)

recTermId ::
  forall r a.
  Lacks "syn" r =>
  Lacks "ctx" r =>
  Lacks "ix" r =>
  Lacks "meta" r =>
  { termId :: ProtoRec ArgsTermId r a } ->
  ProtoRec ArgsTermId r a
recTermId = Rec.recTermId
