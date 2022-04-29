module Language.Shape.Stlc.Recursor.Context where

import Data.Tuple.Nested
import Language.Shape.Stlc.Context
import Language.Shape.Stlc.Syntax
import Prelude
import Prim hiding (Type)
import Prim.Row
import Record
import Data.Default (default)
import Data.Foldable (class Foldable)
import Data.List (List, foldl, zip)
import Language.Shape.Stlc.Recursion.Syntax as Rec
import Language.Shape.Stlc.Recursor.Record (modifyHetero)
import Partial.Unsafe (unsafeCrashWith)
import Prim as Prim
import Type.Proxy (Proxy(..))
import Undefined (undefined)

-- | ProtoRec
type ProtoArgs r1 r2
  = ( argsCtx :: Record ( ctx :: Context | r1 ) | r2 )

type ProtoRec args r a
  = Rec.ProtoRec args r a

_argsCtx = Proxy :: Proxy "argsCtx"

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
  { arrow :: ProtoRec ArgsArrowType r a, data_ :: ProtoRec ArgsDataType r a, hole :: ProtoRec ArgsHoleType r a } ->
  ProtoRec ArgsType r a
recType rec =
  Rec.recType
    { arrow: \args -> rec.arrow args
    , data_: \args -> rec.data_ args
    , hole: \args -> rec.hole args
    }

-- | recTerm
type ProtoArgsTerm r1 r2
  = ProtoArgs ( type_ :: Type | r1 ) r2

type ArgsTerm r
  = Rec.ArgsTerm (ProtoArgsTerm () r)

type ArgsLam r
  = Rec.ArgsLam (ProtoArgsTerm ( type_dom :: Type, ctx_body :: Context, type_body :: Type ) r)

type ArgsNeu r
  = Rec.ArgsNeu (ProtoArgsTerm ( type_id :: Type, types_args :: List Type ) r)

type ArgsLet r
  = Rec.ArgsLet (ProtoArgsTerm ( ctx_body :: Context ) r)

type ArgsBuf r
  = Rec.ArgsBuf (ProtoArgsTerm () r)

type ArgsData r
  = Rec.ArgsData (ProtoArgsTerm ( ctx_body :: Context ) r)

type ArgsMatch r
  = Rec.ArgsMatch (ProtoArgsTerm ( ctx_caseItems :: List Context ) r)

type ArgsHole r
  = Rec.ArgsHole (ProtoArgsTerm () r)

recTerm ::
  forall r a.
  Lacks "argsSyn" r =>
  Lacks "argsCtx" r =>
  { lam :: ProtoRec ArgsLam r a, neu :: ProtoRec ArgsNeu r a, let_ :: ProtoRec ArgsLet r a, buf :: ProtoRec ArgsBuf r a, data_ :: ProtoRec ArgsData r a, match :: ProtoRec ArgsMatch r a, hole :: ProtoRec ArgsHole r a } ->
  ProtoRec ArgsTerm r a
recTerm rec =
  Rec.recTerm
    { lam:
        \args@{ argsSyn: { lam }, argsCtx: { ctx, type_ } } -> case type_ of
          ArrowType { dom, cod } -> rec.lam $ modifyHetero _argsCtx (union { type_dom: dom, ctx_body: insertVarType lam.termBind.termId dom ctx, type_body: cod }) args
          _ -> unsafeCrashWith "badly typed lambda"
    , neu:
        \args@{ argsSyn: { neu }, argsCtx: { ctx } } ->
          let
            type_id = lookupVarType neu.termId ctx

            (types_args /\ _) = flattenType type_id
          in
            rec.neu $ modifyHetero _argsCtx (union { type_id, types_args }) args
    , let_:
        \args@{ argsSyn: { let_ }, argsCtx: { ctx } } ->
          rec.let_ $ modifyHetero _argsCtx (union { ctx_body: insertVarType let_.termBind.termId let_.type_ ctx }) args
    , buf: rec.buf
    , data_:
        \args@{ argsSyn: { data_ }, argsCtx: { ctx } } ->
          rec.data_
            $ modifyHetero _argsCtx
                ( union
                    { ctx_body:
                        flipfoldl
                          ( \sumItem ->
                              insertVarType sumItem.termBind.termId (typeOfConstructor data_.typeBind.typeId sumItem)
                                <<< insertConstrDataType sumItem.termBind.termId { typeId: data_.typeBind.typeId, meta: default }
                          )
                          data_.sumItems
                          $ insertData data_
                          $ ctx
                    }
                )
                args
    , match:
        \args@{ argsSyn: { match }, argsCtx: { ctx, type_ } } ->
          let
            data_ = lookupData match.typeId ctx
          in
            rec.match
              $ modifyHetero _argsCtx
                  ( union
                      { ctx_caseItems:
                          map
                            ( \(caseItem /\ sumItem) ->
                                foldl
                                  (flip \(termBind /\ param) -> insertVarType termBind.termId param.type_)
                                  ctx
                                  (zip caseItem.termBinds sumItem.params)
                            )
                            (zip match.caseItems (data_.sumItems))
                      }
                  )
                  args
    , hole: rec.hole
    }

-- | recArgItems
type ProtoArgsArgItems r1 r2
  = ProtoArgs r1 r2

type ArgsArgItems r
  = Rec.ArgsArgItems (ProtoArgsArgItems ( type_ :: Type ) r)

type ArgsArgItemsCons r
  = Rec.ArgsArgItemsCons (ProtoArgsArgItems ( type_argItem :: Type, type_argItems :: Type ) r)

type ArgsArgItemsNil r
  = Rec.ArgsArgItemsNil (ProtoArgsArgItems ( type_ :: Type ) r)

recArgItems ::
  forall r a.
  Lacks "argsSyn" r =>
  Lacks "argsCtx" r =>
  { cons :: ProtoRec ArgsArgItemsCons r a, nil :: ProtoRec ArgsArgItemsNil r a } ->
  ProtoRec ArgsArgItems r a
recArgItems rec =
  Rec.recArgItems
    { cons:
        rec.cons
          <<< modifyHetero _argsCtx
              ( \{ ctx, type_ } -> case type_ of
                  ArrowType arrow -> { ctx, type_argItem: arrow.dom, type_argItems: arrow.cod }
                  _ -> unsafeCrashWith "term of non-arrow type applied as if it was a function"
              )
    , nil:
        rec.nil
    }

flipfoldl :: forall f a b. Foldable f ⇒ (a → b → b) → f a → b → b
flipfoldl f a = flip (foldl (flip f)) a
