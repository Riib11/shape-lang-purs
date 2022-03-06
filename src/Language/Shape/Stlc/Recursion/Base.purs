module Language.Shape.Stlc.Recursion.Base where

import Language.Shape.Stlc.Syntax
import Prelude
import Prim hiding (Type)
import Data.List (List)
import Language.Shape.Stlc.Metadata
import Undefined (undefined)

recModule ::
  forall a.
  { module_ :: List Definition -> ModuleMetadata -> a
  } ->
  Module ->
  a
recModule rec module_ = case module_ of
  Module defs meta -> rec.module_ defs meta

recBlock ::
  forall a.
  { block :: List Definition -> Term -> BlockMetadata -> a
  } ->
  Block -> a
recBlock rec block = case block of
  Block defs term meta -> rec.block defs term meta

recDefinition ::
  forall a.
  { term :: TermBinding -> Type -> Term -> TermDefinitionMetadata -> a
  , data :: TypeBinding -> (List Constructor) -> DataDefinitionMetadata -> a
  } ->
  Definition -> a
recDefinition rec def = undefined

recConstructor ::
  forall a.
  { constructor :: TermBinding -> Type -> ConstructorMetadata -> a
  } ->
  Constructor -> a
recConstructor rec constr = undefined

recType ::
  forall a.
  { arrow :: Type -> Type -> ArrowTypeMetadata -> a
  , data :: TypeID -> DataTypeMetadata -> a
  , hole :: HoleID -> TypeWeakening -> HoleTypeMetadata -> a
  } ->
  Type -> a
recType rec alpha = undefined

recTerm ::
  forall a.
  { lambda :: TermBinding -> Block -> LambdaTermMetadata -> a
  , neutral :: NeutralTerm -> NeutralTermMetadata -> a
  , match :: TypeID -> Term -> List Term -> MatchTermMetadata -> a
  , hole :: HoleTermMetadata -> a
  } ->
  Term -> a
recTerm rec a = undefined

recNeutralTerm ::
  forall a.
  { variable :: TermID -> VariableTermMetadata -> a
  , application :: NeutralTerm -> Term -> ApplicationTermMetadata -> a
  } ->
  NeutralTerm -> a
recNeutralTerm rec n = undefined
