module Language.Shape.Stlc.Rendering where

import Data.List.Unsafe
import Data.Tuple.Nested
import Language.Shape.Stlc.Index
import Language.Shape.Stlc.Metadata
import Language.Shape.Stlc.RenderingAux
import Language.Shape.Stlc.Syntax
import Language.Shape.Stlc.Typing
import Prelude
import Prim hiding (Type)
import Data.Array as Array
import Data.Map.Unsafe as Map
import Data.Maybe (Maybe(..), maybe)
import Data.Traversable (traverse)
import Data.Tuple (fst, snd)
import Debug as Debug
import Effect (Effect)
import Effect.Class.Console as Console
import Language.Shape.Stlc.Index as Index
import Language.Shape.Stlc.Initial as Initial
import Language.Shape.Stlc.Recursion.Index as RecIndex
import Language.Shape.Stlc.Recursion.MetaContext as RecMetaContext
import Language.Shape.Stlc.Syntax as Syntax
import React as React
import React.DOM as DOM
import React.DOM.Props as Prop
import React.DOM.Props as Props
import React.SyntheticEvent (NativeEvent, NativeEventTarget, stopPropagation, target)
import Record as R
import Undefined (undefined)
import Unsafe as Unsafe
import Web.DOM.DOMTokenList as DOMTokenList
import Web.Event.Event (Event, EventType(..))
import Web.Event.EventTarget (addEventListener, eventListener)
import Web.HTML (HTMLElement, window)
import Web.HTML.HTMLElement (classList)
import Web.HTML.Window (prompt, promptDefault, toEventTarget)

-- import Web.DOM (Element)
-- import Web.DOM.NonElementParentNode (getElementById)
-- import Web.Event.EventTarget (addEventListener, eventListener)
-- import Web.HTML.HTMLDocument (toNonElementParentNode)
-- import Web.HTML.Window (document, toEventTarget)
type ProgramProps
  = {}

type ProgramState
  = { module_ :: Module
    , ix_cursor :: DownwardIndex
    , environment :: Environment
    , outlineParents :: List HTMLElement
    }

type Environment
  = { goal :: Maybe Type
    , gamma :: Context
    , metaGamma :: RecMetaContext.MetaContext
    }

type ProgramGiven
  = { state :: ProgramState
    , render :: Effect React.ReactElement
    , componentDidMount :: Effect Unit
    }

foreign import code :: Event -> String

-- foreign import setNativeEventTargetProp :: forall a. NativeEventTarget -> String -> a -> Effect Unit
-- foreign import getClassName :: NativeEventTarget -> String
foreign import setHTMLElementField :: forall a. String -> a -> HTMLElement -> Effect Unit

foreign import getElementById :: String -> Effect HTMLElement

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
  keyboardEventHandler event = do
    case code event of
      -- "ArrowUp" -> React.modifyState this \st -> st { ix_cursor = moveDownwardIndex Up st.module_ st.ix_cursor }
      -- "ArrowDown" -> React.modifyState this \st -> st { ix_cursor = moveDownwardIndex Down st.module_ st.ix_cursor }
      -- "ArrowLeft" -> React.modifyState this \st -> st { ix_cursor = moveDownwardIndex Left st.module_ st.ix_cursor }
      -- "ArrowRight" -> React.modifyState this \st -> st { ix_cursor = moveDownwardIndex Right st.module_ st.ix_cursor }
      "KeyE" -> do
        st <- React.getState this
        win <- window
        module_ <-
          toModule
            <$> modifySyntaxAtM st.ix_cursor
                ( case _ of
                    SyntaxTermBinding termBinding@(TermBinding termId meta) ->
                      promptDefault "Enter new name" (show meta.name) win
                        >>= case _ of
                            Just str -> pure $ SyntaxTermBinding $ TermBinding termId meta { name = readTermName str }
                            Nothing -> pure $ SyntaxTermBinding termBinding
                    SyntaxTypeBinding typeBinding@(TypeBinding typeId meta) ->
                      promptDefault "Enter new name" (show meta.name) win
                        >>= case _ of
                            Just str -> pure $ SyntaxTypeBinding $ TypeBinding typeId meta { name = readTypeName str }
                            Nothing -> pure $ SyntaxTypeBinding typeBinding
                    x -> pure x
                )
                (SyntaxModule st.module_)
        React.modifyState this \st -> st { module_ = module_ }
      _ -> pure unit
    Debug.traceM event
    pure unit

  state :: ProgramState
  state =
    { module_: Initial.module_
    , ix_cursor: DownwardIndex Nil
    , environment:
        { goal: Nothing
        , gamma: Map.empty
        , metaGamma: RecMetaContext.emptyMetaContext
        }
    , outlineParents: Nil
    }

  render :: ProgramState -> React.ReactElement
  render st =
    DOM.div [ Props.className "editor" ]
      [ renderModule st.module_ Map.empty RecMetaContext.emptyMetaContext (UpwardIndex Nil) (Just st.ix_cursor)
      -- , renderEnvironment st.environment
      ]

  {-
  renderEnvironment :: Environment -> React.ReactElement
  renderEnvironment env =
    let
      contextItemProps termId type_ =
        let
          _ /\ beta = flattenArrowType type_
        in
          [ Props.className $ "context-item"
          -- TODO: this doesnt work with `==` since that's syntactic equality
          -- <> if Just type_ == env.goal then
          --     " suggested exact"
          --   else if Just beta == env.goal then
          --     " suggested apply"
          --   else
          --     ""
          ]
    in
      DOM.div [ Props.className "environment" ]
        $ [ DOM.div
              [ Props.className "context" ]
              ( map
                  ( \(termId /\ type_) ->
                      DOM.div
                        (contextItemProps termId type_)
                        [ renderTermId' termId env.metaGamma
                        , punctuation.space
                        , punctuation.colon
                        , punctuation.space
                        , renderType' type_ Map.empty env.metaGamma -- actually, renderType' shouldn't take a type context at all
                        ]
                  )
                  (Array.reverse $ Map.toUnfoldable env.gamma)
              )
          ]
        <> case env.goal of
            Just type_ ->
              [ DOM.div [ Props.className "goal" ]
                  [ renderType' type_ Map.empty env.metaGamma ]
              ]
            Nothing -> []
  -}
  renderModule :: RecIndex.RecModule React.ReactElement
  renderModule =
    RecIndex.recModule
      { module_:
          \defItems meta gamma metaGamma ix isSelected ix_defItems cursor_defItems ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.div
                ( [ selectableClassName "module" isSelected, Props._id eid ]
                    <> selectableProps ix
                )
                [ renderDefinitionItems defItems gamma metaGamma ix ix_defItems cursor_defItems
                ]
      }

  renderBlock :: RecIndex.RecBlock React.ReactElement
  renderBlock =
    RecIndex.recBlock
      { block:
          \defItems a meta gamma alpha metaGamma ix isSelected ix_defItems cursor_defItems ix_term cursor_term ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "block" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                [ renderDefinitionItems defItems gamma metaGamma ix ix_defItems cursor_defItems
                , indentOrNothing meta metaGamma
                , renderTerm a gamma alpha metaGamma ix_term cursor_term
                ]
      }

  renderDefinitionItems :: RecIndex.RecDefinitionItems React.ReactElement
  renderDefinitionItems =
    RecIndex.recDefinitionItems
      { definitionItems:
          \defItems gamma metaGamma ix_parent ix isSelected ix_def_at cursor_def_at ix_defSep_at cursor_defSep_at ->
            DOM.span
              (inertProps "definitionItems")
              -- [ intersperseRightHTML
              --     [ punctuation.newline, undefined, punctuation.newline ]
              --     $ toUnfoldable
              --     $ mapWithIndex (\i def -> renderDefinition def gamma metaGamma ix (ix_def_at i) (cursor_def_at i)) (fromItem <$> defItems)
              -- ]
              [ DOM.span'
                  $ toUnfoldable
                  $ mapWithIndex
                      ( \i def ->
                          DOM.span'
                            [ indent { indented: true } (R.modify RecMetaContext._indentation (_ - 1) metaGamma)
                            , renderDefinitionSeparator
                                { indented: true }
                                ix
                                (ix_defSep_at i)
                                (cursor_defSep_at i)
                            -- , punctuation.newline
                            , indent { indented: true } (R.modify RecMetaContext._indentation (_ - 1) metaGamma)
                            , renderDefinition def gamma metaGamma ix (ix_def_at i)
                                (cursor_def_at i)
                            -- , punctuation.newline
                            ]
                      )
                      (fromItem <$> defItems)
              , if length defItems == 0 then
                  renderDefinitionSeparator
                    { indented: false }
                    ix
                    (ix_defSep_at (length defItems))
                    (cursor_defSep_at (length defItems))
                else
                  DOM.span'
                    [ indent { indented: true } (R.modify RecMetaContext._indentation (_ - 1) metaGamma)
                    , renderDefinitionSeparator
                        { indented: true }
                        ix
                        (ix_defSep_at (length defItems))
                        (cursor_defSep_at (length defItems))
                    ]
              ]
      }

  renderDefinitionSeparator :: { indented :: Boolean } -> RecIndex.RecDefinitionSeparator React.ReactElement
  renderDefinitionSeparator args =
    RecIndex.recDefinitionSeparator
      { separator:
          \ix_parent ix isSelected ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName ("definitionSeparator separator " <> indentedToClassName args) isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                -- [ DOM.span' $ if args.indented then [] else [ DOM.text "|" ]
                [ DOM.span' [ DOM.text "+" ] ]
      }

  renderDefinition :: RecIndex.RecDefinition React.ReactElement
  renderDefinition =
    RecIndex.recDefinition
      { term:
          \termBinding alpha a meta gamma metaGamma ix_parent ix isSelected ix_termBinding cursor_termBinding ix_alpha cursor_alpha ix_a cursor_a ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "term definition" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                [ renderTermBinding termBinding gamma metaGamma ix_termBinding cursor_termBinding
                , punctuation.space
                , punctuation.colon
                , indentOrSpace meta metaGamma
                , renderType alpha gamma metaGamma ix_alpha cursor_alpha
                , punctuation.newline
                , indentation (R.modify RecMetaContext._indentation (_ - 1) metaGamma)
                , renderTermBinding termBinding gamma metaGamma ix_termBinding cursor_termBinding
                , punctuation.space
                , punctuation.termdef
                , indentOrSpace meta metaGamma
                , renderTerm a gamma alpha metaGamma ix_a cursor_a
                ]
      , data:
          \typeBinding@(TypeBinding typeId _) constrItems meta gamma metaGamma ix_parent ix isSelected ix_typeBinding cursor_typeBinding ix_constrItem_at cursor_constrItem_at ix_constrSep_at cursor_constrSep_at ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "data definition" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                [ renderTypeBinding typeBinding gamma metaGamma ix_typeBinding cursor_typeBinding
                , punctuation.space
                , punctuation.typedef
                , DOM.span'
                    $ Array.fromFoldable
                    $ mapWithIndex
                        ( \i constr ->
                            DOM.span'
                              [ indent { indented: true } metaGamma
                              , renderConstructorSeparator { indented: true } ix ix_parent (ix_constrSep_at i) (cursor_constrSep_at i)
                              , indent { indented: true } metaGamma
                              , renderConstructor constr typeId gamma metaGamma ix ix_parent (ix_constrItem_at i) (cursor_constrItem_at i)
                              ]
                        )
                        (fromItem <$> constrItems)
                , indent { indented: true } metaGamma
                , renderConstructorSeparator { indented: true } ix ix_parent (ix_constrSep_at (length constrItems)) (cursor_constrSep_at (length constrItems))
                ]
      }

  renderConstructorSeparator :: { indented :: Boolean } -> RecIndex.RecConstructorSeparator React.ReactElement
  renderConstructorSeparator args =
    RecIndex.recConstructorSeparator
      { separator:
          \ix_defItems ix_def ix isSelected ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName ("constructorSeparator separator " <> indentedToClassName args) isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                -- [ DOM.span' $ if args.indented then [] else [ DOM.text "|" ] ]
                [ DOM.span' [ DOM.text "+" ] ]
      }

  renderConstructor :: RecIndex.RecConstructor React.ReactElement
  renderConstructor =
    RecIndex.recConstructor
      { constructor:
          \termBinding prmItems meta typeId gamma alpha metaGamma metaGamma_prmItem_at ix_defItems ix_def ix isSelected ix_termBinding cursor_termBinding ix_prmItem_at cursor_prmItem_at ix_prmSep_at cursor_prmSep_at ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "constructor" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                $ [ punctuation.alt
                  , punctuation.space
                  , renderTermBinding termBinding gamma metaGamma ix_termBinding cursor_termBinding
                  , DOM.span
                      (inertProps "constructor parameters")
                      [ intercalateHTML
                          [ punctuation.space ]
                          $ Array.fromFoldable
                          $ mapWithIndex
                              ( \i (prm /\ meta) ->
                                  DOM.span'
                                    [ renderParameterSeparator meta ix_defItems ix_def ix (ix_prmSep_at i) (cursor_prmSep_at i)
                                    , renderParameter prm gamma (metaGamma_prmItem_at i) (ix_prmItem_at i) (cursor_prmItem_at i)
                                    ]
                              )
                              prmItems
                      ]
                  , renderParameterSeparator { indented: any (snd >>> _.indented) prmItems } ix_defItems ix_def ix (ix_prmSep_at (length prmItems)) (cursor_prmSep_at (length prmItems))
                  ]
      }

  renderParameterSeparator :: forall r. { indented :: Boolean | r } -> RecIndex.RecParameterSeparator React.ReactElement
  renderParameterSeparator args =
    RecIndex.recParameterSeparator
      { separator:
          \ix_defItems ix_def ix_constr ix isSelected ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.div
                ( [ selectableClassName ("parameterSeparator separator " <> indentedToClassName args) isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                -- [ DOM.span' $ if args.indented then [] else [ DOM.text "|" ] ]
                [ DOM.span' [ DOM.text "+" ] ]
      }

  renderParameterInsertor :: UpwardIndex -> React.ReactElement
  renderParameterInsertor ix =
    DOM.span
      [ Props.className "parameterInsertor insertor" ]
      [ DOM.text "+" ]

  renderParameterDeletor :: UpwardIndex -> React.ReactElement
  renderParameterDeletor ix =
    DOM.span
      [ Props.className "parameterDeletor deletor" ]
      [ DOM.text "-" ]

  renderType :: RecIndex.RecType React.ReactElement
  renderType type_ gamma metaGamma ix crs =
    DOM.span'
      [ {-renderParameterInsertor ix ,-} RecIndex.recType
          { arrow:
              \prm beta meta gamma metaGamma ix isSelected ix_prm cursor_prm ix_beta cursor_beta ->
                let
                  eid = upwardIndexToEid ix
                in
                  DOM.span
                    ( [ selectableClassName "arrow type" isSelected, Props._id eid ]
                        <> selectableProps ix
                        <> outlineableProps eid
                    )
                    $ [ renderParameter prm gamma metaGamma ix_prm cursor_prm
                      {-, renderParameterDeletor ix-}
                      , punctuation.space
                      ]
                    <> [ punctuation.arrow
                      , punctuation.space
                      , renderType beta gamma metaGamma ix_beta cursor_beta
                      ]
          , data:
              \typeId meta gamma metaGamma ix isSelected ->
                let
                  eid = upwardIndexToEid ix
                in
                  DOM.span
                    ( [ selectableClassName "data type typeId" isSelected, Props._id eid ]
                        <> selectableProps ix
                        <> outlineableProps eid
                    )
                    [ printTypeId typeId metaGamma ]
          , hole:
              \holeId wkn meta gamma metaGamma ix isSelected ->
                let
                  eid = upwardIndexToEid ix
                in
                  DOM.span
                    ( [ selectableClassName "hole type" isSelected, Props._id eid ]
                        <> selectableProps ix
                        <> outlineableProps eid
                    )
                    [ DOM.text "?" ]
          , proxyHole:
              \holeId gamma metaGamma ix isSelected ->
                let
                  eid = upwardIndexToEid ix
                in
                  DOM.span
                    ( [ selectableClassName "proxy hole type" isSelected ]
                        <> selectableProps ix
                        <> outlineableProps eid
                    )
                    [ DOM.text "?" ]
          }
          type_
          gamma
          metaGamma
          ix
          crs
      ]

  renderType' :: RecMetaContext.RecType React.ReactElement
  renderType' =
    RecMetaContext.recType
      { arrow:
          \prm beta meta gamma metaGamma ->
            DOM.span
              (inertProps "arrow type")
              $ [ renderParameter' prm gamma metaGamma
                , punctuation.space
                ]
              <> [ punctuation.arrow
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
  renderTerm term_prt gamma_prt type_prt metaGamma_prt ix_prt crs_prt =
    RecIndex.recTerm
      { lambda:
          \termId block meta gamma prm beta metaGamma ix isSelected ix_termId cursor_termId ix_block cursor_block ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "lambda term" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                $ [ renderTermId termId gamma metaGamma ix_termId cursor_termId ]
                <> [ punctuation.space
                  , punctuation.mapsto
                  , indentOrNothing meta metaGamma
                  , renderBlock block gamma beta metaGamma ix_block cursor_block
                  ]
      , neutral:
          \termId argItems meta gamma alpha metaGamma ix isSelected ix_termId cursor_termId ix_argItems cursor_argItems ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "neutral term" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                [ renderTermId termId gamma metaGamma ix_termId cursor_termId
                , renderArgItems argItems gamma alpha metaGamma ix_argItems cursor_argItems
                ]
      , match:
          \typeId a caseItems meta gamma alpha metaGamma constrIds ix isSelected ix_term cursor_term ix_case_at cursor_case_at ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "match term" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                [ keyword.match
                , punctuation.space
                , renderTerm a gamma (DataType typeId defaultDataTypeMetadata) metaGamma ix_term cursor_term
                , punctuation.space
                , keyword.with
                , DOM.span
                    (inertProps "match caseItems")
                    ( Array.fromFoldable
                        $ mapWithIndex
                            ( \i (case_ /\ meta) ->
                                DOM.span'
                                  [ indentOrSpace meta metaGamma
                                  , renderCase case_ typeId (index' constrIds i) gamma alpha metaGamma ix (ix_case_at i) (cursor_case_at i)
                                  ]
                            )
                            caseItems
                    )
                -- , DOM.span
                --     (inertProps "match caseItems")
                --     [ intercalateHTML [ indentOrSpace meta metaGamma, punctuation.alt, punctuation.space ]
                --         $ Array.fromFoldable
                --         $ mapWithIndex
                --             (\i case_ -> renderCase case_ typeId (index' constrIds i) gamma alpha metaGamma ix (ix_case_at i) (cursor_case_at i))
                --             (fromItem <$> caseItems)
                --     ]
                ]
      , hole:
          \meta gamma alpha metaGamma ix isSelected ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "hole term" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                [ renderType' alpha gamma metaGamma ]
      }
      term_prt
      gamma_prt
      type_prt
      metaGamma_prt
      ix_prt
      crs_prt

  renderArgItems :: RecIndex.RecArgItems React.ReactElement
  renderArgItems =
    RecIndex.recArgItems
      -- TODO: render separator
      { nil: \gamma alpha metaGamma -> DOM.span' []
      , cons:
          \(a /\ argItem_meta) argItems gamma (Parameter alpha _) beta metaGamma ix_a cursor_a ix_argItems cursor_argItems ->
            DOM.span'
              $ [ punctuation.space ]
              <> [ renderTerm a gamma alpha metaGamma ix_a cursor_a ]
              <> if argItems == Nil then
                  []
                else
                  [ punctuation.space
                  , renderArgItems argItems gamma beta metaGamma ix_argItems cursor_argItems
                  ]
      }

  renderCase :: RecIndex.RecCase React.ReactElement
  renderCase case_prt typeId_prt termId_prt gamma_prt alpha_prt metaGamma_prt ix_prt cursor_prt =
    RecIndex.recCase
      { case_:
          \termIdItems block meta typeId constrId gamma alpha metaGamma ix_match ix isSelected ix_termId_at cursor_termId_at ix_term cursor_term ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "case" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                [ punctuation.alt
                , punctuation.space
                , renderTermId' constrId metaGamma
                , DOM.span
                    (inertProps "case termIdItems")
                    [ DOM.span'
                        $ Array.fromFoldable
                        $ mapWithIndex
                            ( \i termId ->
                                DOM.span'
                                  [ punctuation.space
                                  , renderTermId termId gamma metaGamma (ix_termId_at i) (cursor_termId_at i)
                                  ]
                            )
                            (fromItem <$> termIdItems)
                    ]
                , punctuation.space
                , punctuation.mapsto
                , indentOrNothing meta metaGamma
                , renderBlock block gamma alpha metaGamma ix_term cursor_term
                ]
      }
      case_prt
      typeId_prt
      termId_prt
      gamma_prt
      alpha_prt
      metaGamma_prt
      ix_prt
      cursor_prt

  renderParameter :: RecIndex.RecParameter React.ReactElement
  renderParameter =
    RecIndex.recParameter
      { parameter:
          \alpha meta gamma metaGamma ix isSelected ix_alpha cursor_alpha ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "parameter" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                -- [ renderType alpha gamma metaGamma ix_alpha cursor_alpha ]
                [ punctuation.lparen
                , printTermName meta.name metaGamma
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
              -- [ renderType' alpha gamma metaGamma ]
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
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "typeBinding" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                [ printTypeId typeId metaGamma ]
      }

  renderTermBinding :: RecIndex.RecTermBinding React.ReactElement
  renderTermBinding =
    RecIndex.recTermBinding
      { termBinding:
          \termId meta gamma metaGamma ix isSelected ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "termBinding" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                [ printTermId termId metaGamma ]
      }

  renderTermId :: RecIndex.RecTermId React.ReactElement
  renderTermId =
    RecIndex.recTermId
      { termId:
          \termId gamma metaGamma ix isSelected ->
            let
              eid = upwardIndexToEid ix
            in
              DOM.span
                ( [ selectableClassName "termId" isSelected, Props._id eid ]
                    <> selectableProps ix
                    <> outlineableProps eid
                )
                [ printTermId termId metaGamma ]
      }

  renderTermId' :: TermId -> RecMetaContext.MetaContext -> React.ReactElement
  renderTermId' termId metaGamma = DOM.span (inertProps "termId") [ printTermId termId metaGamma ]

  printTypeId :: TypeId -> RecMetaContext.MetaContext -> React.ReactElement
  printTypeId typeId metaGamma = DOM.span [ Props.className "typeId" ] ([ DOM.text typeString ] <> shadow_suffix)
    where
    TypeName typeLabel = Map.lookup' typeId metaGamma.typeScope.names

    typeString = maybe "_" identity typeLabel

    shadow_i = Map.lookup' typeId metaGamma.typeScope.shadowIndices

    shadow_suffix = if shadow_i == 0 then [] else [ printShadowSuffix $ show shadow_i ]

  printTermId :: TermId -> RecMetaContext.MetaContext -> React.ReactElement
  printTermId termId metaGamma = DOM.span' ([ DOM.text termString ] <> shadow_suffix)
    where
    TermName termLabel = Map.lookup' termId metaGamma.termScope.names

    termString = maybe "_" identity termLabel

    shadow_i = Map.lookup' termId metaGamma.termScope.shadowIndices

    shadow_suffix = if shadow_i == 0 then [] else [ printShadowSuffix $ show shadow_i ]

  showTermId :: TermId -> RecMetaContext.MetaContext -> String
  showTermId termId metaGamma = termString <> shadow_suffix
    where
    TermName termLabel = Map.lookup' termId metaGamma.termScope.names

    termString = maybe "_" identity termLabel

    shadow_i = Map.lookup' termId metaGamma.termScope.shadowIndices

    shadow_suffix = if shadow_i == 0 then "" else show shadow_i

  printTermName :: TermName -> RecMetaContext.MetaContext -> React.ReactElement
  printTermName termName@(TermName termLabel) metaGamma = DOM.span [ Props.className "termName" ] ([ DOM.text termString ] <> shadow_suffix)
    where
    termString = maybe "_" identity termLabel

    shadow_i = Map.lookup' termName metaGamma.termScope.shadows

    shadow_suffix = if shadow_i == 0 then [] else [ printShadowSuffix $ show shadow_i ]

  printShadowSuffix :: String -> React.ReactElement
  printShadowSuffix str = DOM.span [ Props.className "shadow-suffix" ] [ DOM.text str ]

  outlineableProps :: String -> Array Props.Props
  outlineableProps eid =  {-[ Prop.onMouseOver \event -> do
        stopPropagation event
        st <- React.getState this
        self <- getElementById eid
        -- if parent on top of stack, then unhighlight it
        -- highlight self
        -- push self to stack
        case st.outlineParents of
          Nil -> pure unit
          Cons parent _ -> unhighlight parent
        highlight self
        React.modifyState this \st -> st { outlineParents = Cons self st.outlineParents }
    , Prop.onMouseOut \event -> do
        stopPropagation event
        st <- React.getState this
        self <- getElementById eid
        -- unhighlight self
        -- pop self from stack
        -- if parent on top of stack, then highlight it
        unhighlight self
        outlineParents' <- case st.outlineParents of
          Nil -> Unsafe.error "tried to pop self, but outlineParents were empty"
          Cons _ Nil -> pure Nil
          Cons _ (Cons parent outlineParents') -> do
            highlight parent
            pure outlineParents'
        React.modifyState this \st -> st { outlineParents = outlineParents' }
    ]-} []

  selectableProps :: UpwardIndex -> Array Props.Props
  selectableProps ix =
    [ Props.onMouseDown \event -> do
        stopPropagation event
        Debug.traceM $ show (toDownwardIndex ix)
        React.modifyState this \st -> st { ix_cursor = toDownwardIndex ix }
    ]

  selectableClassName :: String -> Boolean -> Props.Props
  selectableClassName title isSelected = Props.className $ title <> if isSelected then " selected" else ""

  inertProps :: String -> Array Props.Props
  inertProps title = [ Props.className title ]

highlight :: HTMLElement -> Effect Unit
highlight elem = do
  cls <- classList elem
  isSelected <- DOMTokenList.contains cls "selected"
  if isSelected then
    pure unit
  else
    DOMTokenList.add cls "highlighted"

unhighlight :: HTMLElement -> Effect Unit
unhighlight elem = do
  cls <- classList elem
  DOMTokenList.remove cls "highlighted"

-- highlight :: NativeEventTarget -> Effect Unit
-- highlight t = setNativeEventTargetProp t "style" "box-shadow: 0 0 0 1px purple; background-color: rgba(255, 255, 255, 0.2)"
-- unhighlight :: NativeEventTarget -> Effect Unit
-- unhighlight t = setNativeEventTargetProp t "style" ""
upwardIndexToEid :: UpwardIndex -> String
upwardIndexToEid ix = case unconsUpwardIndex ix of
  Nothing -> ""
  Just { step: IndexStep label i, ix' } -> show label <> "-" <> show i <> "--" <> upwardIndexToEid ix'

indentedToClassName :: forall r. { indented :: Boolean | r } -> String
indentedToClassName { indented } = if indented then "indented" else "nonindented"
