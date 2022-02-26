module Language.Shape.Stlc.Typing where

import Data.Maybe
import Language.Shape.Stlc.Context
import Language.Shape.Stlc.Syntax
import Prelude
import Prim hiding (Type)
import Data.List as List
import Data.Map as Map
import Partial (crashWith)
import Unsafe (lookup)

typeOfNeutralTerm :: NeutralTerm -> Context -> Type
typeOfNeutralTerm (ApplicationTerm id _) gamma = lookup id gamma.termIdType

typeOfNeutralTerm (MatchTerm type_ _ _) gamma = BaseType type_

typeOfNeutralTerm HoleTerm gamma = BaseType (HoleType (freshHoleId unit) List.Nil)
