module Language.Shape.Stlc.Rendering where

import Data.Tuple.Nested
import Language.Shape.Stlc.Types
import Prelude hiding (div)
import React
import Data.Array (intercalate)
import Data.Maybe (Maybe(..))
import Debug as Debug
import Effect (Effect)
import Effect.Console as Console
import Effect.Ref as Ref
import Language.Shape.Stlc.Event.KeyboardEvent (eventKey, handleKey)
import Language.Shape.Stlc.Initial (init1)
import Language.Shape.Stlc.Rendering.Editor (renderEditor)
import Language.Shape.Stlc.Rendering.Syntax
import Language.Shape.Stlc.Rendering.Types
import React.DOM as DOM
import React.Ref as Ref
import Undefined (undefined)
import Web.Event.Event (Event, EventType(..), preventDefault)
import Web.Event.EventTarget (addEventListener, eventListener)
import Web.HTML (window)
import Web.HTML.Window (toEventTarget)

type ReactElements
  = Array ReactElement

programClass :: ReactClass Props
programClass = component "Program" programComponent

programComponent :: ReactThis Props State -> Effect Given
programComponent this = do
  let
    state :: State
    state =
      { mb_ix: Nothing
      , term
      , type_
      , history: mempty
      , clipboard: Nothing
      , dragboard: Nothing
      , highlights: mempty
      , mode: NormalMode
      }
      where
      term /\ type_ = init1
  let
    renEnv = emptyRenderEnvironment state
  renderEnvironmentRef <- Ref.new renEnv
  let
    componentDidMount = do
      Console.log "componentDidMount"
      win <- window
      listener <- eventListener keyboardEventHandler
      addEventListener (EventType "keydown") listener false (toEventTarget win)

    keyboardEventHandler event = do
      -- Debug.traceM event
      -- Debug.traceM $ "===[ keydown: " <> eventKey event <> " ]==============================="
      renEnv <- Ref.read renderEnvironmentRef
      -- Debug.traceM $ "===[ actions ]==============================="
      -- Debug.traceM $ intercalate "\n" <<< map ("- " <> _) <<< map show $ renEnv.actions
      st <- getState this
      case handleKey st renEnv event of
        Just (trigger /\ Action action) -> do
          preventDefault event
          action.effect { this, mb_event: Just event, trigger }
        Nothing -> pure unit

    render = do
      st <- getState this
      -- Debug.traceM (show st)
      renEnv /\ elems <- renderEditor this
      Ref.write renEnv renderEnvironmentRef
      pure elems
  pure
    { state
    , render
    , componentDidMount
    }
