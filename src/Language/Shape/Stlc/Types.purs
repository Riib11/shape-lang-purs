module Language.Shape.Stlc.Types where

import Data.Tuple.Nested
import Language.Shape.Stlc.ChAtIndex
import Language.Shape.Stlc.Context
import Language.Shape.Stlc.Index
import Language.Shape.Stlc.Key
import Language.Shape.Stlc.Metacontext
import Language.Shape.Stlc.Syntax
import Prelude
import Prim hiding (Type)
import Data.Array ((:))
import Data.Array as Array
import Data.Default (default)
import Data.Maybe (Maybe(..), maybe)
import Data.Newtype (class Newtype)
import Debug as Debug
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Language.Shape.Stlc.Changes (applyTC)
import React (ReactElement, ReactThis, getState, modifyState)
import Web.Event.Event (Event)
import Web.HTML (HTMLElement)

type Props
  = {}

type State
  = { term :: Term
    , type_ :: Type
    , mb_ix :: Maybe IxDown
    , history :: History
    , clipboard :: Maybe (IxDown /\ Context /\ Type /\ Term)
    , dragboard :: Maybe (IxDown /\ Context /\ Type /\ Term)
    , highlights :: Array HTMLElement
    , mode :: Mode
    }

-- NOTE: doesn't handle editing binds
data Mode
  = NormalMode
  | QueryMode Query

type Query
  = { query :: String, i :: Int }

derive instance eqMode :: Eq Mode

-- type History = (Term /\ Type /\ Maybe IxDown) /\ Array Change
type History
  = Array HistoryItem

type HistoryItem
  = { term :: Term, type_ :: Type, mb_ix :: Maybe IxDown, change :: Change }

toHistoryItem :: State -> Change -> HistoryItem
toHistoryItem st change =
  { term: st.term
  , type_: st.type_
  , mb_ix: st.mb_ix
  , change: change
  }

type Given
  = { state :: State
    , render :: Effect ReactElement
    , componentDidMount :: Effect Unit
    }

type This
  = ReactThis Props State

newtype Action
  = Action
  { label :: Maybe String
  , triggers :: Array ActionTrigger
  , effect :: ActionEffect
  }

derive instance newtypeAction :: Newtype Action _

type ActionEffect
  = { this :: This, mb_event :: Maybe Event, trigger :: ActionTrigger } -> Effect Unit

data ActionTrigger
  = ActionTrigger_Drop
  | ActionTrigger_Drag
  | ActionTrigger_Hover
  | ActionTrigger_Paste
  | ActionTrigger_Click
  | ActionTrigger_Keypress (Array Key)
  | ActionTrigger_Keytype

derive instance eqActionTrigger :: Eq ActionTrigger

instance showActionTrigger :: Show ActionTrigger where
  show ActionTrigger_Drop = "drop"
  show ActionTrigger_Drag = "drag"
  show ActionTrigger_Hover = "hover"
  show ActionTrigger_Paste = "paste"
  show ActionTrigger_Click = "click"
  show (ActionTrigger_Keypress keys) = "keys[" <> Array.intercalate ", " (show <$> keys) <> "]"
  show ActionTrigger_Keytype = "keytype"

instance showAction :: Show Action where
  show (Action action) =
    ( case action.label of
        Just str -> str <> ": "
        Nothing -> ""
    )
      <> Array.intercalate ", " (show <$> action.triggers)

applyChange :: Change -> State -> Maybe State
applyChange change st = do
  Debug.traceM $ "===[ change ]============================================================"
  Debug.traceM $ show change
  Debug.traceM $ "=========================================================================="
  let
    history = toHistoryItem st change : st.history
  Debug.traceM $ "===[ history (copy this into Test.Main.tests) ]=========================="
  Debug.traceM $ show ((st.type_ /\ st.term) /\ (_.change <$> history))
  Debug.traceM $ "=========================================================================="
  term' /\ ix' /\ typeChange /\ holeEq <- chAtTerm { term: st.term, gamma: default, alpha: st.type_ } change.toReplace change.ix
  -- TODO: apply holeEq
  pure
    st
      { term = term'
      , type_ = applyTC typeChange st.type_
      , mb_ix = Just ix'
      , history = history
      }

doChange :: This -> Change -> Effect Unit
doChange this change = modifyState this \st -> maybe st identity (applyChange change st)
