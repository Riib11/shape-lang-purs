module Language.Shape.Stlc.Rendering where

import Language.Shape.Stlc.Index
import Language.Shape.Stlc.RenderingAux
import Language.Shape.Stlc.Syntax
import Language.Shape.Stlc.Typing
import Prelude
import Prim hiding (Type)
import Data.Array as Array
import Data.List (List)
import Data.List.Unsafe as List
import Data.Map.Unsafe as Map
import Data.Maybe (Maybe(..), maybe)
import Debug as Debug
import Effect (Effect)
import Effect.Class.Console as Console
import Language.Shape.Stlc.Index as Index
import Language.Shape.Stlc.Initial as Initial
import Language.Shape.Stlc.Metadata (TypeName(..), TermName(..), defaultDataTypeMetadata, defaultModuleMetadata)
import Language.Shape.Stlc.Recursion.Index (Cursor, checkCursorStep)
import Language.Shape.Stlc.Recursion.Index as RecIndex
import Language.Shape.Stlc.Recursion.MetaContext (MetaContext, _indentation, emptyMetaContext)
import Language.Shape.Stlc.Recursion.MetaContext as RecMetaContext
import Language.Shape.Stlc.Syntax as Syntax
import React as React
import React.DOM as DOM
import React.DOM.Props as Props
import Record as R
import Undefined (undefined)
import Unsafe as Unsafe
import Web.Event.Event (Event, EventType(..))
import Web.Event.EventTarget (addEventListener, eventListener)
import Web.HTML (window)
import Web.HTML.Window (toEventTarget)

type ProgramProps
  = {}

type ProgramState
  = { module_ :: Module
    , ix_cursor :: Index
    }

type ProgramGiven
  = { state :: ProgramState
    , render :: Effect React.ReactElement
    , componentDidMount :: Effect Unit
    }

foreign import code :: Event -> String

programClass :: React.ReactClass ProgramProps
programClass = React.component "Program" programComponent

programComponent :: React.ReactThis ProgramProps ProgramState -> Effect ProgramGiven
programComponent this =
  pure
    { state
    , render: render <$> React.getState this
    , componentDidMount:
        do
          Console.log "componentDidMount"
          win <- window
          listener <- eventListener keyboardEventHandler
          addEventListener (EventType "keydown") listener false (toEventTarget win)
    }
  where
  keyboardEventHandler :: Event -> Effect Unit
  keyboardEventHandler event = case code event of
    "ArrowUp" -> React.modifyState this \st -> st { ix_cursor = moveIndexUp st.module_ st.ix_cursor }
    "ArrowDown" -> Debug.traceM "ArrowDown"
    "ArrowLeft" -> Debug.traceM "ArrowLeft"
    "ArrowRight" -> Debug.traceM "ArrowRight"
    _ -> pure unit

  state :: ProgramState
  state =
    { module_: Initial.module_
    , ix_cursor: []
    }

  selectableProps :: String -> Boolean -> Index -> Array Props.Props
  selectableProps title isSelected ix =
    [ Props.className $ title <> if isSelected then " selected" else ""
    ]

  selectableTriggerProps :: Index -> Array Props.Props
  selectableTriggerProps ix =
    [ Props.onClick \event -> do
        Debug.traceM $ "setting index to: " <> show ix
        React.modifyState this \st -> st { ix_cursor = ix }
    ]

  inertProps :: String -> Array Props.Props
  inertProps title = [ Props.className title ]

  render :: ProgramState -> React.ReactElement
  render st = renderModule st.module_ Map.empty emptyMetaContext [] (Just st.ix_cursor)

  renderModule :: RecIndex.RecModule React.ReactElement
  renderModule =
    RecIndex.recModule
      { module_:
          \defs meta gamma metaGamma ix isSelected ix_def_at cursor_def_at ->
            DOM.span
              (inertProps "module")
              [ renderDefinitions defs gamma metaGamma ix ix_def_at cursor_def_at ]
      }

  renderBlock :: RecIndex.RecBlock React.ReactElement
  renderBlock =
    RecIndex.recBlock
      { block:
          \defs a meta gamma alpha metaGamma ix isSelected ix_def_at cursor_def_at ix_term cursor_term ->
            DOM.span
              (inertProps "block")
              [ renderDefinitions defs gamma metaGamma ix ix_def_at cursor_def_at
              , renderTerm a gamma alpha metaGamma ix_term cursor_term
              ]
      }

  renderDefinitions :: RecIndex.RecDefinitions React.ReactElement
  renderDefinitions =
    RecIndex.recDefinitions
      { definitions:
          \defs gamma metaGamma ix_mod ix_def_at cursor_def_at ->
            DOM.span
              (inertProps "definitions")
              [ intercalateHTML
                  [ punctuation.newline, punctuation.newline ]
                  $ List.toUnfoldable
                  $ List.mapWithIndex (\i def -> renderDefinition def gamma metaGamma ix_mod (ix_def_at i) (cursor_def_at i)) defs
              ]
      }

  renderDefinition :: RecIndex.RecDefinition React.ReactElement
  renderDefinition =
    RecIndex.recDefinition
      { term:
          \termBinding alpha a meta gamma metaGamma ix_parent ix isSelected ix_termBinding cursor_termBinding ix_alpha cursor_alpha ix_a cursor_a ->
            DOM.span
              (selectableProps "term definition" isSelected ix)
              [ DOM.span (selectableTriggerProps ix)
                  [ renderTermBinding termBinding gamma metaGamma ix_termBinding cursor_termBinding ]
              , punctuation.space
              , punctuation.colon
              , indentOrSpace meta metaGamma
              , renderType alpha gamma metaGamma ix_alpha cursor_alpha
              , punctuation.newline
              , indentation (R.modify _indentation (_ - 1) metaGamma)
              , DOM.span (selectableTriggerProps ix)
                  [ renderTermBinding termBinding gamma metaGamma ix_termBinding cursor_termBinding ]
              , punctuation.space
              , punctuation.termdef
              , indentOrSpace meta metaGamma
              , renderTerm a gamma alpha metaGamma ix_a cursor_a
              ]
      , data:
          \typeBinding@(TypeBinding typeId _) constrs meta gamma metaGamma ix_parent ix isSelected ix_typeBinding cursor_typeBinding ix_constr_at cursor_constr_at ->
            DOM.span
              (selectableProps "data definition" isSelected ix)
              [ DOM.span (selectableTriggerProps ix)
                  [ keyword.data_ ]
              , punctuation.space
              , renderTypeBinding typeBinding gamma metaGamma ix_typeBinding cursor_typeBinding
              , punctuation.space
              , punctuation.typedef
              , DOM.span'
                  [ intersperseLeftHTML
                      [ indentOrSpace { indented: true } metaGamma, punctuation.alt, punctuation.space ]
                      $ Array.fromFoldable
                      $ List.mapWithIndex (\i constr -> renderConstructor constr typeId gamma metaGamma ix ix_parent (ix_constr_at i) (cursor_constr_at i)) constrs
                  ]
              ]
      }

  renderConstructor :: RecIndex.RecConstructor React.ReactElement
  renderConstructor =
    RecIndex.recConstructor
      { constructor:
          \termBinding prms meta typeId gamma alpha metaGamma ix_parent ix_def ix isSelected ix_termBinding cursor_termBinding ix_prm_at cursor_prm_at ->
            DOM.span
              (selectableProps "constructor" isSelected ix)
              $ [ DOM.span (selectableTriggerProps ix)
                    [ renderTermBinding termBinding gamma metaGamma ix_termBinding cursor_termBinding ]
                , punctuation.space
                , punctuation.colon
                , punctuation.space
                , renderType' alpha gamma metaGamma
                ]
      }

  renderType :: RecIndex.RecType React.ReactElement
  renderType =
    RecIndex.recType
      { arrow:
          \prm beta meta gamma metaGamma ix isSelected ix_prm cursor_prm ix_beta cursor_beta ->
            DOM.span
              (selectableProps "arrow type" isSelected ix)
              [ renderParameter prm gamma metaGamma ix_prm cursor_prm
              , punctuation.space
              , punctuation.arrow
              , punctuation.space
              , renderType beta gamma metaGamma ix_beta cursor_beta
              ]
      , data:
          \typeId meta gamma metaGamma ix isSelected ->
            DOM.span
              (selectableProps "data type typeId" isSelected ix <> selectableTriggerProps ix)
              [ printTypeId typeId metaGamma ]
      , hole:
          \holeId wkn meta gamma metaGamma ix isSelected ->
            DOM.span
              (selectableProps "hole type" isSelected ix)
              [ DOM.text "?" ]
      , proxyHole:
          \holeId gamma metaGamma ix isSelected ->
            DOM.span
              (selectableProps "proxy hole type" isSelected ix)
              [ DOM.text "?" ]
      }

  renderType' :: RecMetaContext.RecType React.ReactElement
  renderType' =
    RecMetaContext.recType
      { arrow:
          \prm beta meta gamma metaGamma ->
            DOM.span
              (inertProps "type arrow")
              [ renderParameter' prm gamma metaGamma
              , punctuation.space
              , punctuation.arrow
              , punctuation.space
              , renderType' beta gamma metaGamma
              ]
      , data:
          \typeId meta gamma metaGamma ->
            DOM.span
              (inertProps "data type")
              [ printTypeId typeId metaGamma ]
      , hole:
          \holeId wkn meta gamma metaGamma ->
            DOM.span
              (inertProps "hole type")
              [ DOM.text "?" ]
      , proxyHole:
          \holeId gamma metaGamma ->
            DOM.span
              (inertProps "proxy hole type")
              [ DOM.text "?" ]
      }

  renderTerm :: RecIndex.RecTerm React.ReactElement
  renderTerm =
    RecIndex.recTerm
      { lambda:
          \termId block meta gamma prm beta metaGamma ix isSelected ix_termId cursor_termId ix_block cursor_block ->
            DOM.span
              (selectableProps "lambda term" isSelected ix)
              [ DOM.span (selectableTriggerProps ix)
                  [ keyword.lambda ]
              , punctuation.space
              , renderTermId termId gamma metaGamma ix_termId cursor_termId
              , punctuation.space
              , punctuation.mapsto
              , indentOrSpace meta metaGamma
              , renderBlock block gamma beta metaGamma ix_block cursor_block
              ]
      , neutral:
          \termId args meta gamma alpha metaGamma ix isSelected ix_termId cursor_termId ix_args cursor_args ->
            DOM.span
              (selectableProps "neutral term" isSelected ix)
              [ renderTermId termId gamma metaGamma ix_termId cursor_termId
              , renderArgs args gamma alpha metaGamma ix_args cursor_args
              ]
      , match:
          \typeId a cases meta gamma alpha metaGamma constrIds ix isSelected ix_term cursor_term ix_case_at cursor_case_at ->
            DOM.span
              (selectableProps "match term" isSelected ix)
              [ DOM.span (selectableTriggerProps ix)
                  [ keyword.match ]
              , punctuation.space
              , renderTerm a gamma (DataType typeId defaultDataTypeMetadata) metaGamma ix_term cursor_term
              , punctuation.space
              , keyword.with
              , DOM.span
                  (inertProps "match cases")
                  [ intercalateHTML [ indentOrSpace meta metaGamma, punctuation.alt, punctuation.space ]
                      $ Array.fromFoldable
                      $ List.mapWithIndex
                          (\i case_ -> renderCase case_ typeId (List.index' constrIds i) gamma alpha metaGamma ix (ix_case_at i) (cursor_case_at i))
                          cases
                  ]
              ]
      , hole:
          \holeId meta gamma metaGamma ix isSelected ->
            DOM.span
              (selectableProps "hole term" isSelected ix <> selectableTriggerProps ix)
              [ DOM.text "?" ]
      }

  renderArgs :: RecIndex.RecArgs React.ReactElement
  renderArgs =
    RecIndex.recArgs
      { none: DOM.span' []
      , cons:
          \a args meta gamma (Parameter alpha _) beta metaGamma ix isSelected ix_a cursor_a ix_args cursor_args ->
            DOM.span
              (selectableProps "args" isSelected ix)
              $ [ punctuation.space ]
              <> case a of
                  LambdaTerm _ _ _ -> [ punctuation.lparen, renderTerm a gamma alpha metaGamma ix_a cursor_a, punctuation.lparen ]
                  _ -> [ renderTerm a gamma alpha metaGamma ix_a cursor_a ]
              <> if args == Syntax.NoneArgs then
                  []
                else
                  [ punctuation.space
                  , renderArgs args gamma beta metaGamma ix_args cursor_args
                  ]
      }

  renderCase :: RecIndex.RecCase React.ReactElement
  renderCase =
    RecIndex.recCase
      { case_:
          \termIds term meta typeId constrId gamma alpha metaGamma ix_match ix isSelected ix_termId_at cursor_termId_at ix_term cursor_term ->
            DOM.span
              (selectableProps "case" isSelected ix)
              [ DOM.span (selectableTriggerProps ix)
                  [ renderTermId' constrId metaGamma ]
              , DOM.span
                  (inertProps "case termIds")
                  [ intersperseLeftHTML [ punctuation.space ]
                      $ Array.fromFoldable
                      $ List.mapWithIndex (\i termId -> renderTermId termId gamma metaGamma (ix_termId_at i) (cursor_termId_at i)) termIds
                  ]
              , punctuation.space
              , renderTerm term gamma alpha metaGamma ix_term cursor_term
              ]
      }

  renderParameter :: RecIndex.RecParameter React.ReactElement
  renderParameter =
    RecIndex.recParameter
      { parameter:
          \alpha meta gamma metaGamma ix isSelected ix_alpha cursor_alpha ->
            DOM.span
              (selectableProps "parameter" isSelected ix)
              [ punctuation.lparen
              , DOM.span (selectableTriggerProps ix)
                  [ printTermName meta.name metaGamma ]
              , punctuation.space
              , punctuation.colon
              , punctuation.space
              , renderType alpha gamma metaGamma ix_alpha cursor_alpha
              , punctuation.rparen
              ]
      }

  renderParameter' :: RecMetaContext.RecParameter React.ReactElement
  renderParameter' =
    RecMetaContext.recParameter
      { parameter:
          \alpha meta gamma metaGamma ->
            DOM.span
              (inertProps "parameter")
              [ punctuation.lparen
              , printTermName meta.name metaGamma
              , punctuation.space
              , punctuation.colon
              , punctuation.space
              , renderType' alpha gamma metaGamma
              , punctuation.rparen
              ]
      }

  renderTypeBinding :: RecIndex.RecTypeBinding React.ReactElement
  renderTypeBinding =
    RecIndex.recTypeBinding
      { typeBinding:
          \typeId meta gamma metaGamma ix isSelected ->
            DOM.span (selectableProps "typeBinding" isSelected ix <> selectableTriggerProps ix) [ printTypeId typeId metaGamma ]
      }

  renderTermBinding :: RecIndex.RecTermBinding React.ReactElement
  renderTermBinding =
    RecIndex.recTermBinding
      { termBinding:
          \termId meta gamma metaGamma ix isSelected ->
            DOM.span (selectableProps "termBinding" isSelected ix <> selectableTriggerProps ix) [ printTermId termId metaGamma ]
      }

  renderTermId :: RecIndex.RecTermId React.ReactElement
  renderTermId =
    RecIndex.recTermId
      { termId:
          \termId gamma metaGamma ix isSelected ->
            DOM.span (selectableProps "termId" isSelected ix <> selectableTriggerProps ix) [ printTermId termId metaGamma ]
      }

  renderTermId' :: TermId -> MetaContext -> React.ReactElement
  renderTermId' termId metaGamma = DOM.span (inertProps "termId") [ printTermId termId metaGamma ]

  printTypeId :: TypeId -> MetaContext -> React.ReactElement
  printTypeId typeId metaGamma = DOM.span [ Props.className "typeId" ] ([ DOM.text typeString ] <> shadow_suffix)
    where
    TypeName typeLabel = Map.lookup' typeId metaGamma.typeScope.names

    typeString = maybe "_" identity typeLabel

    shadow_i = Map.lookup' typeId metaGamma.typeScope.shadowIndices

    shadow_suffix = if shadow_i == 0 then [] else [ DOM.sub' [ DOM.text (show shadow_i) ] ]

  printTermId :: TermId -> MetaContext -> React.ReactElement
  printTermId termId metaGamma = DOM.span' ([ DOM.text termString ] <> shadow_suffix)
    where
    TermName termLabel = Map.lookup' termId metaGamma.termScope.names

    termString = maybe "_" identity termLabel

    shadow_i = Map.lookup' termId metaGamma.termScope.shadowIndices

    shadow_suffix = if shadow_i == 0 then [] else [ DOM.sub' [ DOM.text (show shadow_i) ] ]

  printTermName :: TermName -> MetaContext -> React.ReactElement
  printTermName termName@(TermName termLabel) metaGamma = DOM.span [ Props.className "termName" ] ([ DOM.text termString ] <> shadow_suffix)
    where
    termString = maybe "_" identity termLabel

    shadow_i = Map.lookup' termName metaGamma.termScope.shadows

    shadow_suffix = if shadow_i == 0 then [] else [ DOM.sub' [ DOM.text (show shadow_i) ] ]

-- _ = Debug.trace "[!] printTermName" identity
-- _ = Debug.trace termName identity
-- _ = Debug.trace (show metaGamma.termScope.shadows) identity
-- _ = Debug.trace termString identity
-- _ = Debug.trace shadow_i identity
-- _ = Debug.trace shadow_suffix identity
