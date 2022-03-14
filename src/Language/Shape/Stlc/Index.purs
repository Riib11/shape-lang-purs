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
import Unsafe as Unsafe
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

-- returns new syntax and module with new syntax updated in it
visitSyntaxAt :: Index -> (Syntax -> Syntax) -> Module -> Syntax /\ Module
visitSyntaxAt ix f mod = goModule 0 mod
  where 
  l = length ix 

  visit :: forall a. Int -> a -> (a -> Syntax) -> (Syntax -> a) -> (a -> Module) -> (IndexStep -> Syntax /\ Module) -> Syntax /\ Module
  visit i a toSyntax fromSyntax wrap k = if i == l then syntax /\ wrap (fromSyntax syntax) else k (index' ix i)
    where syntax = f $ toSyntax a 

  goModule i mod@(Module defs meta) = visit i mod SyntaxModule toModule identity
    case _ of 
      Module_Definition i_def -> goDefinition (i + 1) (List.index' defs i_def) \def' -> Module (List.updateAt' i_def def' defs) meta
      _ -> Unsafe.error "impossible"

  goDefinition i def wrap = case def of 
    TermDefinition termBinding alpha a meta -> visit i def SyntaxDefinition toDefinition wrap
      case _ of 
        TermDefinition_TermBinding -> goTermBinding (i + 1) termBinding \termBinding' -> TermDefinition termBinding' alpha a meta
        TermDefinition_Type -> goType (i + 1) alpha \alpha' -> TermDefinition termBinding alpha' a meta
        TermDefinition_Term -> goTerm (i + 1) a \a' -> TermDefinition termBinding alpha a' meta
        _ -> Unsafe.error "impossible"
    DataDefinition typeBinding constrs meta -> visit i def SyntaxDefinition toDefinition wrap
      case _ of 
        DataDefinition_TypeBinding -> goTypeBinding (i + 1) typeBinding \typeBinding' -> DataDefinition typeBinding' constrs meta
        DataDefinition_Constructor i_constr -> goConstructor (i + 1) (List.index' constrs i_constr) \constr' -> DataDefinition typeBinding (List.updateAt' i_constr constr' constrs) meta
        _ -> Unsafe.error "impossible"

  goConstructor = undefined
  goType = undefined
  goTerm = undefined
  goTermBinding = undefined
  goTypeBinding = undefined

getSyntaxAt :: Index -> Module -> Syntax
getSyntaxAt ix mod = fst $ visitSyntaxAt ix identity mod 

modifySyntaxAt :: Index -> (Syntax -> Syntax) -> Module -> Module 
modifySyntaxAt ix f mod = snd $ visitSyntaxAt ix identity mod

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