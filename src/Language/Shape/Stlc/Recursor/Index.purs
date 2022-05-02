module Language.Shape.Stlc.Recursor.Index where

import Data.Tuple.Nested
import Language.Shape.Stlc.Context
import Language.Shape.Stlc.Index
import Language.Shape.Stlc.Syntax
import Prelude
import Prim hiding (Type)
import Prim.Row
import Record
import Data.List (List(..), foldl, foldr, snoc)
import Data.List.Unsafe (index')
import Data.Maybe (Maybe(..), isJust)
import Data.Newtype (over, unwrap, wrap)
import Language.Shape.Stlc.Recursor.Context as Rec
import Language.Shape.Stlc.Recursor.Record (modifyHetero)
import Partial.Unsafe (unsafeCrashWith)
import Prim as Prim
import Type.Proxy (Proxy(..))
import Undefined (undefined)

type Cursor
  = Maybe IxDown

type Visit
  = { ix :: IxUp, csr :: Cursor }

isHere :: Visit -> Boolean
isHere { csr } = csr == Just (wrap Nil)

visitIxStep :: Visit -> IxStep -> Visit
visitIxStep { ix, csr } ixStep =
  { ix: over wrap (Cons ixStep) ix
  , csr:
      do
        ixSteps <- unwrap <$> csr
        case ixSteps of
          Cons ixStep' ixSteps' -> if ixStep == ixStep' then Just (wrap ixSteps') else Nothing
          Nil -> Nothing
  }

visitIxDown :: Visit -> IxDown -> Visit
visitIxDown = undefined

-- | ProtoRec
type ProtoArgs r1 r2
  = ( argsIx :: Record ( visit :: Visit | r1 ) | r2 )

type ProtoRec args r a
  = Rec.ProtoRec args r a

_argsIx = Proxy :: Proxy "argsIx"

-- | recType
type ProtoArgsType r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsType r
  = Rec.ArgsType (ProtoArgsType () r)

type ArgsArrowType r
  = Rec.ArgsArrowType (ProtoArgsType ( visit_dom :: Visit, visit_cod :: Visit ) r)

type ArgsDataType r
  = Rec.ArgsDataType (ProtoArgsType () r)

type ArgsHoleType r
  = Rec.ArgsHoleType (ProtoArgsType () r)

recType ::
  forall r a.
  Lacks "argsSyn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  { arrow :: ProtoRec ArgsArrowType r a, data_ :: ProtoRec ArgsDataType r a, hole :: ProtoRec ArgsHoleType r a } ->
  ProtoRec ArgsType r a
recType rec =
  Rec.recType
    { arrow: rec.arrow <<< modifyHetero _argsIx (\argsIx@{ visit } -> union { visit_dom: visitIxStep visit ixStepArrowType.dom, visit_cod: visitIxStep visit ixStepArrowType.cod } argsIx)
    , data_: rec.data_
    , hole: rec.hole
    }

-- -- | recTerm
type ProtoArgsTerm r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsTerm r
  = Rec.ArgsTerm (ProtoArgsTerm () r)

type ArgsLam r
  = Rec.ArgsLam (ProtoArgsTerm ( visit_termBind :: Visit, visit_body :: Visit ) r)

type ArgsNeu r
  = Rec.ArgsNeu (ProtoArgsTerm ( visit_termId :: Visit, visit_argItems :: Visit ) r)

type ArgsLet r
  = Rec.ArgsLet (ProtoArgsTerm ( visit_termBind :: Visit, visit_type :: Visit, visit_term :: Visit, visit_body :: Visit ) r)

type ArgsBuf r
  = Rec.ArgsBuf (ProtoArgsTerm ( visit_term :: Visit, visit_body :: Visit ) r)

type ArgsData r
  = Rec.ArgsData (ProtoArgsTerm ( visit_typeBind :: Visit, visit_sum :: Visit, visit_body :: Visit ) r)

type ArgsMatch r
  = Rec.ArgsMatch (ProtoArgsTerm ( visit_term :: Visit, visit_caseItems :: Visit ) r)

type ArgsHole r
  = Rec.ArgsHole (ProtoArgsTerm () r)

recTerm ::
  forall r a.
  Lacks "argsSyn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  { lam :: ProtoRec ArgsLam r a, neu :: ProtoRec ArgsNeu r a, let_ :: ProtoRec ArgsLet r a, buf :: ProtoRec ArgsBuf r a, data_ :: ProtoRec ArgsData r a, match :: ProtoRec ArgsMatch r a, hole :: ProtoRec ArgsHole r a } ->
  ProtoRec ArgsTerm r a
recTerm rec =
  Rec.recTerm
    { lam: rec.lam <<< modifyHetero _argsIx (\argsIx@{ visit } -> union { visit_termBind: visitIxStep visit ixStepLam.termBind, visit_body: visitIxStep visit ixStepLam.body } argsIx)
    , neu: rec.neu <<< modifyHetero _argsIx (\argsIx@{ visit } -> union { visit_termId: visitIxStep visit ixStepNeu.termId, visit_argItems: visitIxStep visit ixStepNeu.argItems } argsIx)
    , let_: rec.let_ <<< modifyHetero _argsIx (\argsIx@{ visit } -> union { visit_termBind: visitIxStep visit ixStepLet.termBind, visit_type: visitIxStep visit ixStepLet.type_, visit_term: visitIxStep visit ixStepLet.term, visit_body: visitIxStep visit ixStepLet.body } argsIx)
    , buf: rec.buf <<< modifyHetero _argsIx (\argsIx@{ visit } -> union { visit_term: visitIxStep visit ixStepBuf.term, visit_body: visitIxStep visit ixStepBuf.body } argsIx)
    , data_: rec.data_ <<< modifyHetero _argsIx (\argsIx@{ visit } -> union { visit_typeBind: visitIxStep visit ixStepData.typeBind, visit_sum: visitIxStep visit ixStepData.sum, visit_body: visitIxStep visit ixStepData.body } argsIx)
    , match: rec.match <<< modifyHetero _argsIx (\argsIx@{ visit } -> union { visit_term: visitIxStep visit ixStepMatch.term, visit_caseItems: visitIxStep visit ixStepMatch.caseItems } argsIx)
    , hole: rec.hole
    }

-- -- | recArgItems
-- type ProtoArgsArgItems r1 r2
--   = ProtoArgs r1 r2
-- type ArgsArgItems r
--   = Rec.ArgsArgItems (ProtoArgsArgItems () r)
-- type ArgsArgItemsCons r
--   = Rec.ArgsArgItemsCons (ProtoArgsArgItems ( visit_argItem :: Visit, visit_argItems :: Visit ) r)
-- type ArgsArgItemsNil r
--   = Rec.ArgsArgItemsNil (ProtoArgsArgItems () r)
-- recArgItems ::
--   forall r a.
--   Lacks "argsSyn" r =>
--   Lacks "argsCtx" r =>
--   Lacks "argsIx" r =>
--   { cons :: ProtoRec ArgsArgItemsCons r a, nil :: ProtoRec ArgsArgItemsNil r a } ->
--   ProtoRec ArgsArgItems r a
-- recArgItems rec =
--   Rec.recArgItems
--     { cons: rec.cons <<< modifyHetero _argsIx (\argsIx@{ visit } -> union { visit_argItem: visitIxStep visit ixStepArgItems.argItem, visit_argItems: visitIxStep visit ixStepArgItems.argItems } argsIx)
--     , nil: rec.nil
--     }
-- | recArgItems
type ProtoArgsArgItems r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsArgItems r
  = Rec.ArgsArgItems (ProtoArgsArgItems () r)

type ArgsArgItem r
  = Rec.ArgsArgItem (ProtoArgsArgItems ( visits_argItems :: List Visit, visit_argItem :: Visit ) r)

recArgItems ::
  forall r a.
  Lacks "argsSyn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  { argItem :: ProtoRec ArgsArgItem r a } ->
  ProtoRec ArgsArgItems r (List a)
recArgItems rec =
  Rec.recArgItems { argItem: \args@{ argsSyn, argsIx } -> rec.argItem $ modifyHetero _argsIx (union { visit_argItem: index' argsIx.visits_argItems argsSyn.i }) args }
    <<< \args@{ argsSyn, argsIx } ->
        modifyHetero _argsIx
          ( union
              { visits_argItems:
                  ( foldl
                        (\{ visit, visits_argItems } _ -> { visit: visitIxStep visit ixStepList.head, visits_argItems: snoc visits_argItems (visitIxStep visit ixStepList.tail) })
                        { visit: argsIx.visit, visits_argItems: mempty }
                        argsSyn.argItems
                    )
                    .visits_argItems
              }
          )
          args

-- | recSumItems
type ProtoArgsSumItems r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsSumItems r
  = Rec.ArgsSumItems (ProtoArgsSumItems () r)

type ArgsSumItem r
  = Rec.ArgsSumItem (ProtoArgsSumItems ( visits_sumItems :: List Visit, visit_sumItem :: Visit, visit_termBind :: Visit, visit_params :: Visit ) r)

recSumItems ::
  forall r a.
  Lacks "argsSyn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  { sumItem :: ProtoRec ArgsSumItem r a } ->
  ProtoRec ArgsSumItems r (List a)
recSumItems rec =
  Rec.recSumItems
    { sumItem:
        \args@{ argsSyn, argsIx } ->
          let
            visit_sumItem = index' argsIx.visits_sumItems argsSyn.i

            visit_termBind = visitIxStep visit_sumItem ixStepSumItem.termBind

            visit_params = visitIxStep visit_sumItem ixStepSumItem.params
          in
            rec.sumItem $ modifyHetero _argsIx (union { visit_sumItem, visit_termBind, visit_params }) args
    }
    <<< \args@{ argsSyn, argsIx } ->
        modifyHetero _argsIx
          ( union
              { visits_sumItems:
                  ( foldl
                        (\{ visit, visits_sumItems } _ -> { visit: visitIxStep visit ixStepList.head, visits_sumItems: snoc visits_sumItems (visitIxStep visit ixStepList.tail) })
                        { visit: argsIx.visit, visits_sumItems: mempty }
                        argsSyn.sumItems
                    )
                    .visits_sumItems
              }
          )
          args

-- | recCaseItems
type ProtoArgsCaseItems r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsCaseItems r
  = Rec.ArgsCaseItems (ProtoArgsCaseItems () r)

type ArgsCaseItem r
  = Rec.ArgsCaseItem (ProtoArgsCaseItems ( visits_caseItems :: List Visit, visit_caseItem :: Visit, visit_termBinds :: Visit, visit_body :: Visit ) r)

recCaseItems ::
  forall r a.
  Lacks "argsSyn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  { caseItem :: ProtoRec ArgsCaseItem r a } ->
  ProtoRec ArgsCaseItems r (List a)
recCaseItems rec =
  Rec.recCaseItems
    { caseItem:
        \args@{ argsSyn, argsIx } ->
          let
            visit_caseItem = index' argsIx.visits_caseItems argsSyn.i

            visit_termBinds = visitIxStep visit_caseItem ixStepCaseItem.termBinds

            visit_body = visitIxStep visit_caseItem ixStepCaseItem.body
          in
            rec.caseItem $ modifyHetero _argsIx (union { visit_caseItem, visit_termBinds, visit_body }) args
    }
    <<< \args@{ argsSyn, argsIx } ->
        modifyHetero _argsIx
          ( union
              { visits_caseItems:
                  ( foldl
                        (\{ visit, visits_caseItems } _ -> { visit: visitIxStep visit ixStepList.head, visits_caseItems: snoc visits_caseItems (visitIxStep visit ixStepList.tail) })
                        { visit: argsIx.visit, visits_caseItems: mempty }
                        argsSyn.caseItems
                    )
                    .visits_caseItems
              }
          )
          args

-- | recParams
type ProtoArgsParams r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsParams r
  = Rec.ArgsParams (ProtoArgsParams () r)

type ArgsParam r
  = Rec.ArgsParam (ProtoArgsParams ( visits_params :: List Visit, visit_param :: Visit, visit_type :: Visit ) r)

recParams ::
  forall r a.
  Lacks "argsSyn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  { param :: ProtoRec ArgsParam r a } ->
  ProtoRec ArgsParams r (List a)
recParams rec =
  -- Rec.recParams { param: \args@{ argsSyn, argsIx } -> rec.param $ modifyHetero _argsIx (union { visit_param: index' argsIx.visits_params argsSyn.i }) args }
  Rec.recParams
    { param:
        \args@{ argsSyn, argsIx } ->
          let
            visit_param = index' argsIx.visits_params argsSyn.i

            visit_type = visitIxStep visit_param ixStepParam.type_
          in
            rec.param $ modifyHetero _argsIx (union { visit_param, visit_type }) args
    }
    <<< \args@{ argsSyn, argsIx } ->
        modifyHetero _argsIx
          -- TODO: same fixes as to recCaseItems
          ( union
              { visits_params:
                  ( foldl
                        (\{ visit, visits_params } _ -> { visit: visitIxStep visit ixStepList.head, visits_params: snoc visits_params (visitIxStep visit ixStepList.tail) })
                        { visit: argsIx.visit, visits_params: mempty }
                        argsSyn.params
                    )
                    .visits_params
              }
          )
          args

-- | recTermBinds
type ProtoArgsTermBinds r1 r2
  = ProtoArgs ( | r1 ) r2

type ArgsTermBinds r
  = Rec.ArgsTermBinds (ProtoArgsTermBinds () r)

type ArgsTermBind r
  = Rec.ArgsTermBind (ProtoArgsTermBinds ( visits_termBinds :: List Visit, visit_termBind :: Visit ) r)

recTermBinds ::
  forall r a.
  Lacks "argsSyn" r =>
  Lacks "argsCtx" r =>
  Lacks "argsIx" r =>
  { termBind :: ProtoRec ArgsTermBind r a } ->
  ProtoRec ArgsTermBinds r (List a)
recTermBinds rec =
  Rec.recTermBinds { termBind: \args@{ argsSyn, argsIx } -> rec.termBind $ modifyHetero _argsIx (union { visit_termBind: index' argsIx.visits_termBinds argsSyn.i }) args }
    <<< \args@{ argsSyn, argsIx } ->
        modifyHetero _argsIx
          ( union
              { visits_termBinds:
                  ( foldl
                        (\{ visit, visits_termBinds } _ -> { visit: visitIxStep visit ixStepList.head, visits_termBinds: snoc visits_termBinds (visitIxStep visit ixStepList.tail) })
                        { visit: argsIx.visit, visits_termBinds: mempty }
                        argsSyn.termBinds
                    )
                    .visits_termBinds
              }
          )
          args
