module Language.Shape.Stlc.Rendering where

import AppAction
import Data.Tuple.Nested
import Language.Shape.Stlc.Metadata
import Language.Shape.Stlc.RenderingAux
import Language.Shape.Stlc.Syntax
import Prelude
import Prim hiding (Type)
import Data.List.Unsafe (List)
import Data.List.Unsafe as List
import Data.Map.Unsafe as Map
import Data.Maybe (Maybe(..))
import Data.Symbol (class IsSymbol)
import Data.Tuple as Tuple
import Debug as Debug
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Language.Shape.Stlc.Recursion.MetaContext (MetaContext)
import Language.Shape.Stlc.Recursion.MetaContext as RecMeta
import Language.Shape.Stlc.Recursion.Wrap (Wrap, IndexWrap)
import Language.Shape.Stlc.Recursion.Wrap as RecWrap
import Language.Shape.Stlc.Typing (Context)
import Prim.Row (class Cons)
import Type.Proxy (Proxy(..))
import Undefined (undefined)
import Unsafe as Unsafe

{-
Universal syntax interface
-}
type SyntaxComponent q m
  = H.Component q SyntaxState AppAction m

type SyntaxState
  = { cursor :: Boolean
    }

type SyntaxSlot q
  = H.Slot q AppAction Int

type SyntaxSlots q
  = ( module :: SyntaxSlot q
    , definitions :: SyntaxSlot q
    , definition :: SyntaxSlot q
    , block :: SyntaxSlot q
    , constructor :: SyntaxSlot q
    , type :: SyntaxSlot q
    , term :: SyntaxSlot q
    , args :: SyntaxSlot q
    , case_ :: SyntaxSlot q
    , parameter :: SyntaxSlot q
    , typeName :: SyntaxSlot q
    , termName :: SyntaxSlot q
    )

_module = Proxy :: Proxy "module"

_definitions = Proxy :: Proxy "definitions"

_definition = Proxy :: Proxy "definition"

_block = Proxy :: Proxy "block"

_constructor = Proxy :: Proxy "constructor"

_type = Proxy :: Proxy "type"

_term = Proxy :: Proxy "term"

_args = Proxy :: Proxy "args"

_case = Proxy :: Proxy "case_"

_parameter = Proxy :: Proxy "parameter"

_typeName = Proxy :: Proxy "typeName"

_termName = Proxy :: Proxy "termName"

data SyntaxAction
  = AppAction AppAction
  | ModifyState (SyntaxState -> SyntaxState)

initialSyntaxState :: SyntaxState
initialSyntaxState =
  { cursor: false
  }

mkSyntaxComponent ::
  forall q m.
  (SyntaxState -> HH.ComponentHTML SyntaxAction (SyntaxSlots q) m) ->
  SyntaxComponent q m
mkSyntaxComponent render =
  H.mkComponent
    { initialState:
        const
          { cursor: false
          }
    , eval:
        H.mkEval
          H.defaultEval
            { handleAction =
              case _ of
                AppAction appAction -> H.raise appAction
                ModifyState modifyState -> H.modify_ modifyState
            -- , receive = Just <<< ModifyState <<< const
            }
    , render: render
    }

slotSyntax ::
  forall label slot q m _1.
  IsSymbol label =>
  Ord slot =>
  Cons label (H.Slot q AppAction slot) _1 (SyntaxSlots q) =>
  Proxy label ->
  slot ->
  SyntaxComponent q m ->
  H.ComponentHTML SyntaxAction (SyntaxSlots q) m
slotSyntax label i html = HH.slot label i html initialSyntaxState AppAction

{-
Universal syntax utilities
-}
classSyntax :: forall r i. SyntaxState -> String -> HP.IProp ( class ∷ String | r ) i
classSyntax st label = HP.class_ (HH.ClassName $ label <> if st.cursor then " selected" else "")

{-
Specific syntax renderers
-}
renderModule :: forall q m. Module -> Context -> MetaContext -> Wrap Module -> SyntaxComponent q m
renderModule =
  RecWrap.recModule
    { module_:
        \defs meta gamma metaGamma wrap_defs ->
          mkSyntaxComponent \st ->
            HH.span
              [ classSyntax st "module" ]
              [ slotSyntax _definitions 0 $ renderDefinitions defs gamma metaGamma wrap_defs ]
    }

renderBlock :: forall q m. Block -> Context -> Type -> MetaContext -> Wrap Block -> SyntaxComponent q m
renderBlock =
  RecWrap.recBlock
    { block:
        \defs a meta gamma alpha metaGamma wrap_defs wrap_a ->
          mkSyntaxComponent \st ->
            HH.span
              [ classSyntax st "block" ]
              [ slotSyntax _definitions 0 $ renderDefinitions defs gamma metaGamma wrap_defs
              , punctuation.newline
              , slotSyntax _term 0 $ renderTerm a gamma alpha metaGamma wrap_a
              ]
    }

renderDefinitions :: forall q m. List Definition -> Context -> MetaContext -> Wrap (List Definition) -> SyntaxComponent q m
renderDefinitions =
  RecWrap.recDefinitions
    { definitions:
        \defs gamma metaGamma wrap_defs ->
          let
            renderDefinition def wrap_def = case def of
              TermDefinition x alpha a meta ->
                mkSyntaxComponent \st ->
                  HH.span
                    [ classSyntax st "term definition" ]
                    [ keyword.let_
                    , punctuation.space
                    , slotSyntax _termName 0 $ renderTermBinding x gamma metaGamma
                    , punctuation.space
                    , punctuation.colon
                    , punctuation.space
                    , slotSyntax _type 0 $ renderType alpha gamma metaGamma (wrap_def <<< \alpha' -> TermDefinition x alpha' a meta)
                    , punctuation.space
                    , punctuation.termdef
                    , punctuation.space
                    , slotSyntax _term 0 $ renderTerm a gamma alpha metaGamma (wrap_def <<< \a' -> TermDefinition x alpha a meta)
                    ]
              DataDefinition typeId constrs meta ->
                mkSyntaxComponent \st ->
                  HH.span
                    [ classSyntax st "data definition" ]
                    [ keyword.data_
                    , punctuation.space
                    , slotSyntax _typeName 0 $ renderTypeBinding typeId gamma metaGamma
                    , punctuation.space
                    , punctuation.typedef
                    , punctuation.space
                    , intercalateHTML (List.fromFoldable [ punctuation.space, punctuation.alt, punctuation.space ])
                        ( List.mapWithIndex
                            ( \i constr ->
                                slotSyntax _constructor i $ renderConstructor constr gamma typeId metaGamma (wrap_def <<< \constr' -> DataDefinition typeId (List.updateAt' i constr' constrs) meta)
                            )
                            constrs
                        )
                    ]
          in
            mkSyntaxComponent \st ->
              HH.span
                [ classSyntax st "definitions" ]
                [ intercalateHTML (List.singleton punctuation.newline)
                    $ List.mapWithIndex
                        ( \i def ->
                            slotSyntax _definition i
                              $ (renderDefinition def (wrap_defs <<< \def' -> List.updateAt' i def' defs))
                        )
                        defs
                ]
    }

renderConstructor :: forall q m. Constructor -> Context -> TypeBinding -> MetaContext -> Wrap Constructor -> SyntaxComponent q m
renderConstructor =
  RecWrap.recConstructor
    { constructor:
        \x prms meta gamma xType metaGamma wrap_prm_at ->
          mkSyntaxComponent \st ->
            HH.span [ classSyntax st "constructor" ]
              $ [ slotSyntax _termName 0 $ renderTermBinding x gamma metaGamma
                , punctuation.space
                , punctuation.colon
                , punctuation.space
                ]
              {-
              TODO:
              Should I just render the type of constructor by looking it up in
              context? The problem is that I need the types still to know their
              place in the constructor's parameters, so that typechanges are
              derived correctly.
              -}
              
              <> ( if List.length prms > 0 then
                    [ intercalateHTML (List.fromFoldable [ punctuation.space, punctuation.arrow, punctuation.space ])
                        ( List.mapWithIndex
                            ( \i prm ->
                                slotSyntax _parameter i
                                  $ renderParameter prm gamma metaGamma (wrap_prm_at i)
                            )
                            prms
                        )
                    , punctuation.space
                    , punctuation.arrow
                    ]
                  else
                    []
                )
              <> [ slotSyntax _termName 0 $ renderTypeBinding xType gamma metaGamma ]
    }

renderType :: forall q m. Type -> Context -> MetaContext -> Wrap Type -> SyntaxComponent q m
renderType =
  RecWrap.recType
    { arrow:
        \prm beta meta gamma metaGamma wrap_prm wrap_alpha ->
          mkSyntaxComponent \st ->
            HH.span
              [ classSyntax st "arrow type" ]
              [ slotSyntax _parameter 0 $ renderParameter prm gamma metaGamma wrap_prm
              , punctuation.space
              , punctuation.arrow
              , punctuation.space
              , slotSyntax _type 0 $ renderType beta gamma metaGamma wrap_alpha
              ]
    , data:
        \id meta gamma metaGamma ->
          mkSyntaxComponent \st ->
            HH.span
              [ classSyntax st "data type" ]
              [ slotSyntax _typeName 0 $ renderTypeId id gamma metaGamma
              ]
    , hole:
        \id wkn meta gamma metaGamma ->
          mkSyntaxComponent \st ->
            HH.span
              [ classSyntax st "hole type" ]
              [ HH.text "?" ]
    , proxyHole:
        \id gamma metaGamma ->
          mkSyntaxComponent \st ->
            HH.span
              [ classSyntax st "hole proxy type" ]
              [ HH.text "?" ]
    }

renderTerm :: forall q m. Term -> Context -> Type -> MetaContext -> Wrap Term -> SyntaxComponent q m
renderTerm =
  RecWrap.recTerm
    { lambda:
        \termId block meta gamma beta metaGamma wrap_block ->
          mkSyntaxComponent \st ->
            HH.span
              [ classSyntax st "term lambda" ]
              [ slotSyntax _termName 0 $ renderTermId termId gamma metaGamma
              , punctuation.lparen
              , punctuation.space
              , punctuation.mapsto
              , punctuation.space
              , slotSyntax _block 0 $ renderBlock block gamma beta metaGamma wrap_block
              , punctuation.rparen
              ]
    , neutral:
        \termId args meta gamma alpha metaGamma wrap_neu ->
          mkSyntaxComponent \st ->
            HH.span
              [ classSyntax st "term neutral" ]
              -- [ slotSyntax _neutralTerm 0 $ renderNeutralTerm neu gamma alpha metaGamma wrap_neu ]
              [ slotSyntax _termName 0 $ renderTermId termId gamma metaGamma
              , undefined -- TODO
              ]
    , hole:
        \meta gamma alpha metaGamma ->
          mkSyntaxComponent \st ->
            HH.span
              [ classSyntax st "term hole" ]
              [ HH.text "?" ]
    , match:
        \typeId a cases meta gamma alpha metaGamma constrIDs wrap_a wrap_case_at ->
          mkSyntaxComponent \st ->
            HH.span
              [ classSyntax st "term match" ]
              [ keyword.match
              , punctuation.space
              , slotSyntax _term 0 $ renderTerm a gamma (DataType typeId defaultDataTypeMetadata) metaGamma wrap_a
              , punctuation.space
              , keyword.with
              , punctuation.space
              , intercalateHTML (List.fromFoldable [ punctuation.space, punctuation.alt, punctuation.space ])
                  ( List.mapWithIndex
                      ( \i (case_ /\ constrID) ->
                          slotSyntax _case i
                            $ renderCase case_ gamma alpha typeId constrID metaGamma (wrap_case_at i)
                      )
                      (List.zip cases constrIDs)
                  )
              ]
    }

renderArgs :: forall q m. Args -> Context -> List Type -> MetaContext -> Wrap Args -> SyntaxComponent q m
renderArgs =
  RecWrap.recArgs
    { none: mkSyntaxComponent \st -> HH.span_ []
    , cons:
        \a args meta gamma alpha alphas metaGamma wrap_a wrap_args ->
          mkSyntaxComponent \st ->
            HH.span
              [ classSyntax st "arg" ]
              [ slotSyntax _term 0 $ renderTerm a gamma alpha metaGamma wrap_a
              , punctuation.space
              , slotSyntax _args 0 $ renderArgs args gamma alphas metaGamma wrap_args
              ]
    }

renderCase :: forall q m. Case -> Context -> Type -> TypeId -> TermId -> MetaContext -> Wrap Case -> SyntaxComponent q m
renderCase =
  RecWrap.recCase
    { case_:
        \termIds a meta gamma alpha typeId constrID metaGamma wrap_a ->
          mkSyntaxComponent \st ->
            HH.span
              [ classSyntax st "case" ]
              [ slotSyntax _termName 0 $ renderTermId constrID gamma metaGamma
              , intersperseLeftHTML (List.singleton punctuation.space)
                  ( List.mapWithIndex
                      ( \i termId ->
                          slotSyntax _termName i
                            $ renderTermId termId gamma metaGamma
                      )
                      termIds
                  )
              , punctuation.space
              , punctuation.mapsto
              , slotSyntax _term 0 $ renderTerm a gamma alpha metaGamma wrap_a
              ]
    }

renderParameter :: forall q m. Parameter -> Context -> MetaContext -> Wrap Parameter -> SyntaxComponent q m
renderParameter =
  RecWrap.recParameter
    { parameter:
        \alpha meta gamma metaGamma wrap_alpha ->
          let
            shadowIndex = Map.lookup' meta.name metaGamma.termScope.shadows
          in
            mkSyntaxComponent \st ->
              HH.span
                [ classSyntax st "parameter" ]
                [ punctuation.lparen
                , slotSyntax _termName 0 $ renderTermName meta.name shadowIndex gamma metaGamma
                , punctuation.space
                , punctuation.colon
                , punctuation.space
                , slotSyntax _type 0 $ renderType alpha gamma metaGamma wrap_alpha
                , punctuation.rparen
                ]
    }

renderTypeBinding :: forall q m. TypeBinding -> Context -> MetaContext -> SyntaxComponent q m
renderTypeBinding (TypeBinding id meta) gamma metaGamma = renderTypeName meta.name shadowIndex gamma metaGamma
  where
  shadowIndex = Map.lookup' id metaGamma.typeScope.shadowIndices

renderTermBinding :: forall q m. TermBinding -> Context -> MetaContext -> SyntaxComponent q m
renderTermBinding (TermBinding id meta) gamma metaGamma = renderTermName meta.name shadowIndex gamma metaGamma
  where
  shadowIndex = Map.lookup' id metaGamma.termScope.shadowIndices

renderTypeId :: forall q m. TypeId -> Context -> MetaContext -> SyntaxComponent q m
renderTypeId id gamma metaGamma = renderTypeName name shadowIndex gamma metaGamma
  where
  name = Map.lookup' id metaGamma.typeScope.names

  shadowIndex = Map.lookup' id metaGamma.typeScope.shadowIndices

renderTermId :: forall q m. TermId -> Context -> MetaContext -> SyntaxComponent q m
renderTermId id gamma metaGamma = renderTermName name shadowIndex gamma metaGamma
  where
  name = Map.lookup' id metaGamma.termScope.names

  shadowIndex = Map.lookup' id metaGamma.termScope.shadowIndices

renderTypeName :: forall q m. TypeName -> Int -> Context -> MetaContext -> SyntaxComponent q m
renderTypeName (TypeName name) shadowIndex gamma metaGamma =
  let
    shadowSuffix = if shadowIndex > 0 then show shadowIndex else ""
  in
    mkSyntaxComponent \st ->
      HH.span
        [ classSyntax st "type name" ]
        [ case name of
            Just label -> HH.text $ label <> shadowSuffix
            Nothing -> HH.text "_"
        ]

renderTermName :: forall q m. TermName -> Int -> Context -> MetaContext -> SyntaxComponent q m
renderTermName (TermName name) shadowIndex gamma metaGamma =
  let
    shadowSuffix = if shadowIndex > 0 then show shadowIndex else ""
  in
    mkSyntaxComponent \st ->
      HH.span
        [ classSyntax st "term name" ]
        [ case name of
            Just label -> HH.text $ label <> shadowSuffix
            Nothing -> HH.text "_"
        ]
