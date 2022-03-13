module Language.Shape.Stlc.Index where

import Data.Array.Unsafe
import Data.Tuple.Nested
import Language.Shape.Stlc.Syntax
import Prelude

import Data.Eq.Generic (genericEq)
import Data.Generic.Rep (class Generic)
import Data.List.Unsafe as List
import Data.Maybe (Maybe(..))
import Data.Show.Generic (genericShow)
import Data.Tuple (fst, snd)
import Undefined (undefined)
import Unsafe (error)
import Unsafe.Coerce (unsafeCoerce)

type Index
  = Array IndexStep

data IndexStep
  = Module_Definition Int
  | Block_Definition Int
  | Block_Term
  | TermDefinition_TermBinding
  | TermDefinition_Type
  | TermDefinition_Term
  | DataDefinition_TypeBinding
  | DataDefinition_Constructor Int
  | Constructor_TermBinding
  | Constructor_Parameter Int
  | LambdaTerm_TermId
  | LambdaTerm_Block
  | HoleTerm
  | MatchTerm_Term
  | MatchTerm_Case Int
  | NeutralTerm_TermId
  | NeutralTerm_Args
  | NoneArgs
  | ConsArgs_Term
  | ConsArgs_Args
  | Case_TermId Int
  | Case_Term
  | ArrowType_Parameter
  | ArrowType_Type
  | Parameter_Type

derive instance Generic IndexStep _
instance Show IndexStep where show step = genericShow step
instance Eq IndexStep where eq step step' = genericEq step step' 

pushIndex :: Index -> IndexStep -> Index
pushIndex = snoc

infix 5 pushIndex as :>

visitSyntaxAt :: Index -> (Syntax -> Syntax) -> Module -> Syntax /\ Module
visitSyntaxAt ix f mod = undefined

getSyntaxAt :: Index -> Module -> Syntax
getSyntaxAt ix mod = fst $ visitSyntaxAt ix identity mod 

modifySyntaxAt :: Index -> (Syntax -> Syntax) -> Module -> Module 
modifySyntaxAt ix f mod = snd $ visitSyntaxAt ix identity mod

-- TODO
-- setMetadataAt :: forall a. Index -> a -> Module -> Module 
-- setMetadataAt ix meta' = goModule 
  -- where 
  -- l = length ix
  -- goModule i (Module defs meta) =
  --   if i == l - 1
  --     then Module defs (unsafeCoerce meta')
  --     else case index' ix i of
  --       Module_Definition j -> Module (List.updateAt' j (goDefinition (i + 1) (List.index' defs j)) defs) meta
  --       _ -> error "impossible"
  -- goDefinition i (TermDefinition termBinding alpha a meta) =
  --   if i == l - 1
  --     then TermDefinition termBinding alpha a $ unsafeCoerce meta'
  --     else case index' ix i of 
  --       TermDefinition_TermBinding -> TermDefinition (goTermBinding (i + 1) termBinding) alpha a meta
  --       TermDefinition_Type -> TermDefinition termBinding (goType (i + 1) alpha) a meta
  --       TermDefinition_Term -> TermDefinition termBinding alpha (goTerm (i + 1) a) meta
  --       _ -> error "impossible"
  -- goDefinition i (DataDefinition typeBinding constrs meta) = undefined
  -- goType = undefined 
  -- goTerm = undefined 
  -- goTermBinding = undefined 


data Direction = Up | Down | Left | Right

moveIndex :: Direction -> Index -> Index 
moveIndex dir ix = ix 

moveIndexUp :: Module -> Index -> Index 
moveIndexUp _ ix = case unsnoc ix of 
  Nothing -> []
  Just {init: ix'} -> ix' 

moveIndexLeft :: Module -> Index -> Index 
moveIndexLeft mod ix = ix 

moveIndexRight :: Module -> Index -> Index 
moveIndexRight mod ix = ix 

moveIndexDown :: Module -> Index -> Index 
moveIndexDown mod ix = ix 