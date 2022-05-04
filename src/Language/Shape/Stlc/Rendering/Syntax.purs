module Language.Shape.Stlc.Rendering.Syntax where

import Language.Shape.Stlc.Syntax
import Prelude
import Prim hiding (Type)
import Control.Monad.State (State)
import Control.Monad.State as State
import Data.Array (concat)
import Data.Default (default)
import Data.List (List)
import Data.List as List
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.OrderedSet (OrderedSet)
import Data.OrderedSet as OrderedSet
import Data.Set (Set)
import Data.Set as Set
import Data.Traversable (sequence)
import Language.Shape.Stlc.Context (Context(..))
import Language.Shape.Stlc.Metacontext (Metacontext(..))
import Language.Shape.Stlc.Recursor.Action as RecAct
import Language.Shape.Stlc.Recursor.Context as RecCtx
import Language.Shape.Stlc.Recursor.Index (Visit)
import Language.Shape.Stlc.Recursor.Index as RecIx
import Language.Shape.Stlc.Recursor.Metacontext as RecMeta
import Language.Shape.Stlc.Rendering.Keyword (token)
import Language.Shape.Stlc.Types (Action(..), This, getState')
import Prim.Row (class Union)
import React (ReactElement)
import React.DOM (span, text)
import React.DOM.Props (className)
import Record (union)
import Undefined (undefined)

renderProgram :: This -> Array ReactElement
renderProgram this =
  flip State.evalState mempty
    $ renderTerm
        -- TODO: maybe pull this out into multiple files or at least somewhere else?
        { act: {}
        , ctx: { ctx: default, type_: HoleType { holeId: freshHoleId unit, weakening: Set.empty, meta: default } }
        , meta: { meta: default }
        , ix: { visit: { csr: Just st.ix, ix: mempty } }
        , syn: { term: st.term }
        }
  where
  st = getState' this

renderType :: RecAct.ProtoRec RecAct.ArgsType () (Array ReactElement)
renderType =
  RecAct.recType
    { arrow:
        \args ->
          renderNode
            ( (useArgsCtx_Type args $ useArgsIx args $ useArgsAct args $ defaultNodeProps)
                { label = Just "ArrowType" }
            )
            [ renderType { syn: { type_: args.syn.arrow.dom }, ctx: args.ctx, ix: { visit: args.ix.dom }, meta: { meta: args.meta.dom }, act: {} }
            , pure [ token.arrowType1 ]
            , renderType { syn: { type_: args.syn.arrow.cod }, ctx: args.ctx, ix: { visit: args.ix.cod }, meta: { meta: args.meta.cod }, act: {} }
            ]
    , data_:
        \args ->
          renderNode
            ( (useArgsCtx_Type args $ useArgsIx args $ useArgsAct args $ defaultNodeProps)
                { label = Just "DataType" }
            )
            [ pure $ printTypeId { typeId: args.syn.data_.typeId, meta: args.meta.meta }
            ]
    , hole:
        \args ->
          renderNode
            ( (useArgsCtx_Type args $ useArgsIx args $ useArgsAct args $ defaultNodeProps)
                { label = Just "HoleType" }
            )
            [ printHoleId { holeId: args.syn.hole.holeId, meta: args.meta.meta }
            ]
    }

renderTerm :: RecAct.ProtoRec RecAct.ArgsTerm () (Array ReactElement)
renderTerm =
  RecAct.recTerm
    { lam:
        \args ->
          renderNode
            ( (useArgsCtx_Term args $ useArgsIx args $ useArgsAct args $ defaultNodeProps)
                { label = Just "Lam" }
            )
            [ pure [ token.lam1 ]
            , renderTermBind { syn: { termBind: args.syn.lam.termBind }, ctx: { ctx: args.ctx.ctx }, ix: { visit: args.ix.termBind }, meta: { meta: args.meta.meta }, act: {} }
            , pure [ token.lam2 ]
            , renderTerm { syn: { term: args.syn.lam.body }, ctx: args.ctx.body, ix: { visit: args.ix.body }, meta: { meta: args.meta.body }, act: {} }
            ]
    , neu:
        \args ->
          renderNode
            ( (useArgsCtx_Term args $ useArgsIx args $ useArgsAct args $ defaultNodeProps)
                { label = Just "Neu" }
            )
            if List.length args.syn.neu.argItems == 0 then
              [ renderTermId { syn: { termId: args.syn.neu.termId }, ctx: { ctx: args.ctx.termId }, ix: { visit: args.ix.termId }, meta: { meta: args.meta.meta }, act: {} }
              ]
            else
              [ renderTermId { syn: { termId: args.syn.neu.termId }, ctx: { ctx: args.ctx.termId }, ix: { visit: args.ix.termId }, meta: { meta: args.meta.meta }, act: {} }
              , pure [ token.neu1 ]
              , renderArgItems { syn: { argItems: args.syn.neu.argItems }, ctx: args.ctx.argItems, ix: { visit: args.ix.argItems }, meta: { meta: args.meta.argItems }, act: {} }
              ]
    , let_:
        \args ->
          renderNode
            ( (useArgsCtx_Term args $ useArgsIx args $ useArgsAct args $ defaultNodeProps)
                { label = Just "Let" }
            )
            [ pure [ token.let1 ]
            , renderTermBind { syn: { termBind: args.syn.let_.termBind }, ctx: { ctx: args.ctx.ctx }, ix: { visit: args.ix.termBind }, meta: { meta: args.meta.meta }, act: {} }
            , pure [ token.let2 ]
            , renderType { syn: { type_: args.syn.let_.type_ }, ctx: { ctx: args.ctx.ctx }, ix: { visit: args.ix.type_ }, meta: { meta: args.meta.type_ }, act: {} }
            , pure [ token.let3 ]
            , renderTerm { syn: { term: args.syn.let_.term }, ctx: args.ctx.term, ix: { visit: args.ix.term }, meta: { meta: args.meta.term }, act: {} }
            , pure [ token.let4 ]
            , renderTerm { syn: { term: args.syn.let_.body }, ctx: args.ctx.body, ix: { visit: args.ix.body }, meta: { meta: args.meta.body }, act: {} }
            ]
    , buf:
        \args ->
          renderNode
            ( (useArgsCtx_Term args $ useArgsIx args $ useArgsAct args $ defaultNodeProps)
                { label = Just "Buf" }
            )
            [ pure [ token.buf1 ]
            , renderTerm { syn: { term: args.syn.buf.term }, ctx: args.ctx.term, ix: { visit: args.ix.term }, meta: { meta: args.meta.term }, act: {} }
            , pure [ token.buf2 ]
            , renderType { syn: { type_: args.syn.buf.type_ }, ctx: { ctx: args.ctx.ctx }, ix: { visit: args.ix.type_ }, meta: { meta: args.meta.meta }, act: {} }
            , pure [ token.buf3 ]
            , renderTerm { syn: { term: args.syn.buf.body }, ctx: args.ctx.body, ix: { visit: args.ix.body }, meta: { meta: args.meta.body }, act: {} }
            ]
    , data_:
        \args ->
          renderNode
            ( (useArgsCtx_Term args $ useArgsIx args $ useArgsAct args $ defaultNodeProps)
                { label = Just "Data" }
            )
            [ pure [ token.data1 ]
            , renderTypeBind { syn: { typeBind: args.syn.data_.typeBind }, ctx: { ctx: args.ctx.ctx }, ix: { visit: args.ix.typeBind }, meta: { meta: args.meta.meta }, act: {} }
            , pure [ token.data2 ]
            , renderSumItems { syn: { sumItems: args.syn.data_.sumItems }, ctx: { ctx: args.ctx.ctx }, ix: { visit: args.ix.sumItems }, meta: { meta: args.meta.sumItems }, act: {} }
            , pure [ token.data3 ]
            , renderTerm { syn: { term: args.syn.data_.body }, ctx: args.ctx.body, ix: { visit: args.ix.body }, meta: { meta: args.meta.body }, act: {} }
            ]
    , match:
        \args ->
          renderNode
            ( (useArgsCtx_Term args $ useArgsIx args $ useArgsAct args $ defaultNodeProps)
                { label = Just "Match" }
            )
            [ pure [ token.match1 ]
            , renderTerm { syn: { term: args.syn.match.term }, ctx: args.ctx.term, ix: { visit: args.ix.term }, meta: { meta: args.meta.term }, act: {} }
            , pure [ token.match2 ]
            , renderCaseItems { syn: { caseItems: args.syn.match.caseItems }, ctx: args.ctx.caseItems, ix: { visit: args.ix.caseItems }, meta: { meta: args.meta.caseItems }, act: {} }
            ]
    , hole:
        \args ->
          renderNode
            ( (useArgsCtx_Term args $ useArgsIx args $ useArgsAct args $ defaultNodeProps)
                { label = Just "Hole" }
            )
            [ renderType { syn: { type_: args.ctx.type_ }, ctx: { ctx: args.ctx.ctx }, ix: { visit: { csr: Nothing, ix: Nothing } }, meta: { meta: args.meta.meta }, act: {} }
            ]
    }

renderArgItems :: RecAct.ProtoRec RecAct.ArgsArgItems () (Array ReactElement)
renderArgItems =
  (List.foldl append [] <$> _)
    <<< RecAct.recArgItems
        { argItem:
            \args ->
              renderNode
                ( (useArgsIx args $ useArgsAct args $ defaultNodeProps)
                    { label = Just "ArgItem"
                    , ctx = Just args.ctx.ctx
                    }
                )
                -- TODO: indent con item.indent
                []
        }

renderSumItems :: RecAct.ProtoRec RecAct.ArgsSumItems () (Array ReactElement)
renderSumItems = undefined

renderCaseItems :: RecAct.ProtoRec RecAct.ArgsCaseItems () (Array ReactElement)
renderCaseItems = undefined

renderParamItems :: RecAct.ProtoRec RecAct.ArgsParamItems () (Array ReactElement)
renderParamItems = undefined

renderTermBindItems :: RecAct.ProtoRec RecAct.ArgsTermBindItems () (Array ReactElement)
renderTermBindItems = undefined

renderTermBind :: RecAct.ProtoRec RecAct.ArgsTermBind () (Array ReactElement)
renderTermBind = undefined

renderTypeBind :: RecAct.ProtoRec RecAct.ArgsTypeBind () (Array ReactElement)
renderTypeBind = undefined

renderTypeId :: RecAct.ProtoRec RecAct.ArgsTypeId () (Array ReactElement)
renderTypeId = undefined

renderTermId :: RecAct.ProtoRec RecAct.ArgsTermId () (Array ReactElement)
renderTermId = undefined

printTypeId :: { typeId :: TypeId, meta :: Metacontext } -> Array ReactElement
printTypeId = undefined

printTermId :: { termId :: TermId, meta :: Metacontext } -> Array ReactElement
printTermId = undefined

printHoleId :: { holeId :: HoleId, meta :: Metacontext } -> State (OrderedSet HoleId) (Array ReactElement)
printHoleId args = do
  i <- OrderedSet.findIndex (args.holeId == _) <$> State.get
  pure [ span [ className "holeId" ] [ text $ show i ] ]

type NodeProps
  = { label :: Maybe String
    , visit :: Maybe Visit
    , type_ :: Maybe Type
    , ctx :: Maybe Context
    , meta :: Maybe Metacontext
    , actions :: Array Action
    }

defaultNodeProps :: NodeProps
defaultNodeProps =
  { label: default
  , visit: default
  , type_: default
  , ctx: default
  , meta: default
  , actions: []
  }

maybeArray :: forall a b. Maybe a -> (a -> b) -> Array b
maybeArray ma f = case ma of
  Just a -> [ f a ]
  Nothing -> []

useArgsCtx_Type :: forall r1 r2. Record (RecCtx.ProtoArgsType r1 r2) -> NodeProps -> NodeProps
useArgsCtx_Type { ctx } = _ { ctx = Just ctx.ctx }

useArgsCtx_Term :: forall r1 r2. Record (RecCtx.ProtoArgsTerm r1 r2) -> NodeProps -> NodeProps
useArgsCtx_Term { ctx } = _ { ctx = Just ctx.ctx, type_ = Just ctx.type_ }

useArgsMeta :: forall r1 r2. { meta :: { meta :: Metacontext | r1 } | r2 } -> NodeProps -> NodeProps
useArgsMeta { meta } = _ { meta = Just meta.meta }

useArgsIx :: forall r1 r2. Record (RecIx.ProtoArgs r1 r2) -> NodeProps -> NodeProps
useArgsIx { ix } = _ { visit = Just (ix.visit) }

useArgsAct :: forall r1 r2. Record (RecAct.ProtoArgs ( actions :: Array Action | r1 ) r2) -> NodeProps -> NodeProps
useArgsAct { act } = _ { actions = act.actions }

renderNode :: NodeProps -> Array (State (OrderedSet HoleId) (Array ReactElement)) -> State (OrderedSet HoleId) (Array ReactElement)
renderNode props elemsM = do
  elems <- concat <$> sequence elemsM
  pure
    $ [ span
          (className # maybeArray props.label)
          elems
      ]
