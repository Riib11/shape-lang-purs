module Language.Shape.Stlc.Recursion.Index where

import Data.Either
import Data.List.Unsafe
import Data.Maybe
import Data.Tuple.Nested
import Language.Shape.Stlc.Index
import Language.Shape.Stlc.Metadata
import Language.Shape.Stlc.Syntax
import Language.Shape.Stlc.Typing
import Prelude
import Prim hiding (Type)
import Control.Monad.State (State, runState)
import Data.Foldable (foldl)
import Data.Map (Map)
import Data.Map as Map
import Debug as Debug
import Language.Shape.Stlc.Changes as Ch
import Language.Shape.Stlc.Holes (HoleSub)
import Language.Shape.Stlc.Recursion.MetaContext (MetaContext)
import Language.Shape.Stlc.Recursion.MetaContext as RecMetaContext
import Undefined (undefined)
import Unsafe as Unsafe

type Cursor
  = Maybe DownwardIndex

-- check to see if the next step of the recursion "downward" corresponds to the next downward step of the cursor
checkCursorStep :: IndexStep -> Cursor -> Cursor
checkCursorStep step' csr = do
  ix <- csr
  { step, ix' } <- unconsDownwardIndex ix
  if step == step' then
    Just ix'
  else
    Nothing

checkCursorSteps :: DownwardIndex -> Cursor -> Cursor
checkCursorSteps ix csr = case unconsDownwardIndex ix of
  Just { step, ix' } -> checkCursorSteps ix' $ checkCursorStep step csr
  Nothing -> csr

checkCursorHere :: Cursor -> Boolean
checkCursorHere = case _ of
  Nothing -> false
  Just (DownwardIndex steps) -> null steps

-- Recursion principles for handling indexing
type RecModule a
  = RecMetaContext.RecModule (UpwardIndex -> Cursor -> a)

type RecModule_Module a
  = RecMetaContext.RecModule_Module
      ( UpwardIndex -> -- module
        Boolean -> -- module
        UpwardIndex -> -- definitionItems
        Cursor -> -- definitionItems
        a
      )

recModule ::
  forall a.
  { module_ :: RecModule_Module a } ->
  RecModule a
recModule rec =
  RecMetaContext.recModule
    { module_:
        \defs meta gamma metaGamma ix csr ->
          rec.module_ defs meta gamma metaGamma
            -- module
            ix
            (checkCursorHere csr)
            -- definitionItems
            (ix :- IndexStep StepModule 0)
            (checkCursorStep (IndexStep StepModule 0) csr)
    }

type RecBlock a
  = RecMetaContext.RecBlock (UpwardIndex -> Cursor -> a)

type RecBlock_Block a
  = RecMetaContext.RecBlock_Block
      ( UpwardIndex -> -- block
        Boolean -> -- block
        -- (Int -> UpwardIndex) -> -- definition
        -- (Int -> Cursor) -> -- definition
        UpwardIndex -> -- definitionItems
        Cursor -> -- definitionItems
        UpwardIndex -> -- term
        Cursor -> -- term
        a
      )

recBlock ::
  forall a.
  { block :: RecBlock_Block a } ->
  RecBlock a
recBlock rec =
  RecMetaContext.recBlock
    { block:
        \defs a meta gamma alpha metaGamma ix csr ->
          rec.block defs a meta gamma alpha metaGamma
            -- block
            ix
            (checkCursorHere csr)
            -- definitionItems
            (ix :- IndexStep StepBlock 0)
            (checkCursorStep (IndexStep StepBlock 0) csr)
            -- term
            (ix :- IndexStep StepBlock 1)
            (checkCursorStep (IndexStep StepBlock 1) csr)
    }

type RecDefinitionItems a
  = RecMetaContext.RecDefinitionItems
      ( UpwardIndex -> -- module/block
        UpwardIndex -> Cursor -> a
      )

type RecDefinitionItems_DefinitionItems a
  = RecMetaContext.RecDefinitionItems_DefinitionItems
      ( UpwardIndex -> -- module/block
        UpwardIndex -> -- definitionItems
        Boolean -> -- definitionItems
        (Int -> UpwardIndex) -> -- definition
        (Int -> Cursor) -> -- definition
        (Int -> UpwardIndex) -> -- definitionSeparator
        (Int -> Cursor) -> -- definitionSeparator
        a
      )

recDefinitionItems ::
  forall a.
  { definitionItems :: RecDefinitionItems_DefinitionItems a } ->
  RecDefinitionItems a
recDefinitionItems rec =
  RecMetaContext.recDefinitionItems
    { definitionItems:
        \defItems gamma metaGamma ix_parent ix csr ->
          rec.definitionItems defItems gamma metaGamma
            -- module/block
            ix_parent
            -- definitionItems
            ix
            (checkCursorHere csr)
            -- defItem
            (\i -> ix <> (fromListIndexToUpwardIndex i <> singletonUpwardIndex (IndexStep StepDefinitionItem 0)))
            (\i -> checkCursorSteps (fromListIndexToDownwardIndex i <> singletonDownwardIndex (IndexStep StepDefinitionItem 0)) csr)
            -- defSep
            (\i -> ix <> fromSublistIndexToUpwardIndex i)
            (\i -> checkCursorSteps (fromSublistIndexToDownwardIndex i) csr)
    }

type RecDefinitionSeparator a
  = UpwardIndex -> -- module/block
    UpwardIndex -> -- definitionSeparator
    Cursor -> -- definitionSeparator
    a

type RecDefinitionSeparator_Separator a
  = UpwardIndex -> -- module/block
    UpwardIndex -> -- definitionSeparator
    Boolean -> -- definitionSeparator
    a

recDefinitionSeparator ::
  forall a.
  { separator :: RecDefinitionSeparator_Separator a } ->
  RecDefinitionSeparator a
recDefinitionSeparator rec ix_parent ix csr =
  rec.separator
    ix_parent
    ix
    (checkCursorHere csr)

type RecDefinition a
  = RecMetaContext.RecDefinition
      ( UpwardIndex -> -- module/block
        UpwardIndex -> -- definition
        Cursor -> -- definition
        a
      )

type RecDefinition_TermDefinition a
  = RecMetaContext.RecDefinition_TermDefinition
      ( UpwardIndex -> -- module/block
        UpwardIndex -> -- definition
        Boolean -> -- definition
        UpwardIndex -> -- termId
        Cursor -> -- termId
        UpwardIndex -> -- type
        Cursor -> -- type
        UpwardIndex -> -- term
        Cursor -> -- term
        a
      )

type RecDefinition_DataDefinition a
  = RecMetaContext.RecDefinition_DataDefinition
      ( UpwardIndex -> -- module/block
        UpwardIndex -> -- definition
        Boolean -> -- definition
        UpwardIndex -> -- typeBinding
        Cursor -> -- typeBinding
        (Int -> UpwardIndex) -> -- constructorItems
        (Int -> Cursor) -> -- constructorItems
        (Int -> UpwardIndex) -> -- constructorSeps
        (Int -> Cursor) -> -- constructorSeps
        a
      )

recDefinition ::
  forall a.
  { term :: RecDefinition_TermDefinition a
  , data :: RecDefinition_DataDefinition a
  } ->
  RecDefinition a
recDefinition rec =
  RecMetaContext.recDefinition
    { term:
        \termBinding alpha a meta gamma metaGamma ix_parent ix csr ->
          rec.term termBinding alpha a meta gamma metaGamma
            -- module/block
            ix_parent
            -- definition
            ix
            (checkCursorHere csr)
            -- termBinding
            (ix :- IndexStep StepTermDefinition 0)
            (checkCursorStep (IndexStep StepTermDefinition 0) csr)
            -- type
            (ix :- IndexStep StepTermDefinition 1)
            (checkCursorStep (IndexStep StepTermDefinition 1) csr)
            -- term
            (ix :- IndexStep StepTermDefinition 2)
            (checkCursorStep (IndexStep StepTermDefinition 2) csr)
    , data:
        \typeBinding constrs meta gamma metaGamma ix_parent ix csr ->
          let
            _ = unit -- if isJust csr then Debug.trace ("data" /\ ix /\ csr) identity else unit
          in
            rec.data typeBinding constrs meta gamma metaGamma
              -- module/block
              ix_parent
              -- definition
              ix
              (checkCursorHere csr)
              -- typeBinding
              (ix :- IndexStep StepDataDefinition 0)
              (checkCursorStep (IndexStep StepDataDefinition 0) csr)
              -- constructorItems
              (\i -> ix <> singletonUpwardIndex (IndexStep StepDataDefinition 1) <> fromListIndexToUpwardIndex i <> singletonUpwardIndex (IndexStep StepConstructorItem 0))
              (\i -> checkCursorSteps (singletonDownwardIndex (IndexStep StepDataDefinition 1) <> fromListIndexToDownwardIndex i <> singletonDownwardIndex (IndexStep StepConstructorItem 0)) csr)
              -- constructorSeps
              (\i -> ix <> singletonUpwardIndex (IndexStep StepDataDefinition 1) <> fromSublistIndexToUpwardIndex i)
              (\i -> checkCursorSteps (singletonDownwardIndex (IndexStep StepDataDefinition 1) <> fromSublistIndexToDownwardIndex i) csr)
    }

type RecConstructorSeparator a
  = UpwardIndex -> -- definitionItems
    UpwardIndex -> -- definition
    UpwardIndex -> -- constructorSeparator
    Cursor -> -- constructorSeparator
    a

type RecConstructorSeparator_Separator a
  = UpwardIndex -> -- definitionItems
    UpwardIndex -> -- definition
    UpwardIndex -> -- constructorSeparator
    Boolean -> -- constructorSeparator
    a

recConstructorSeparator ::
  forall a.
  { separator :: RecConstructorSeparator_Separator a } ->
  RecConstructorSeparator a
recConstructorSeparator rec ix_defItems ix_def ix csr =
  rec.separator
    ix_defItems
    ix_def
    ix
    (checkCursorHere csr)

type RecConstructor a
  = RecMetaContext.RecConstructor
      ( UpwardIndex -> -- definitionItems
        UpwardIndex -> -- definition
        UpwardIndex -> -- constructor
        Cursor -> -- constructor
        a
      )

type RecConstructor_Constructor a
  = RecMetaContext.RecConstructor_Constructor
      ( UpwardIndex -> -- definitionItems
        UpwardIndex -> -- definition
        UpwardIndex -> -- constructor
        Boolean -> -- constructor
        UpwardIndex -> -- termBinding
        Cursor -> -- termBinding
        (Int -> UpwardIndex) -> -- parameterItems
        (Int -> Cursor) -> -- parameters
        (Int -> UpwardIndex) -> -- parameterSeps
        (Int -> Cursor) -> -- parameterSeps
        a
      )

-- registration already handled by recDefinitionItems
recConstructor ::
  forall a.
  { constructor :: RecConstructor_Constructor a } ->
  RecConstructor a
recConstructor rec =
  RecMetaContext.recConstructor
    { constructor:
        \termBinding prms meta typeId gamma alpha metaGamma metaGamma_prm_at ix_parent ix_def ix csr ->
          let
            _ = unit -- if isJust csr then Debug.trace ("constructor" /\ ix /\ csr) identity else unit
          in
            rec.constructor termBinding prms meta typeId gamma alpha metaGamma metaGamma_prm_at
              ix_parent
              ix_def
              -- constructor
              ix
              (checkCursorHere csr)
              -- termBinding
              (ix :- IndexStep StepConstructor 0)
              (checkCursorStep (IndexStep StepConstructor 0) csr)
              -- parameterItems
              (\i -> ix <> singletonUpwardIndex (IndexStep StepConstructor 1) <> fromListIndexToUpwardIndex i <> singletonUpwardIndex (IndexStep StepParameterItem 0))
              (\i -> checkCursorSteps (singletonDownwardIndex (IndexStep StepConstructor 1) <> fromListIndexToDownwardIndex i <> singletonDownwardIndex (IndexStep StepParameterItem 0)) csr)
              -- parameterSeps
              (\i -> ix <> singletonUpwardIndex (IndexStep StepConstructor 1) <> fromSublistIndexToUpwardIndex i)
              (\i -> checkCursorSteps (singletonDownwardIndex (IndexStep StepConstructor 1) <> fromSublistIndexToDownwardIndex i) csr)
    }

type RecParameterSeparator a
  = UpwardIndex -> -- definitionItems
    UpwardIndex -> -- definition
    UpwardIndex -> -- constructor
    UpwardIndex -> -- parameterSep
    Cursor -> -- parameterSep
    a

type RecParameterSeparator_Separator a
  = UpwardIndex -> -- definitionItems
    UpwardIndex -> -- definition
    UpwardIndex -> -- constructor
    UpwardIndex -> -- parameterSep
    Boolean -> -- parameterSep
    a

recParameterSeparator ::
  forall a.
  { separator :: RecParameterSeparator_Separator a } ->
  RecParameterSeparator a
recParameterSeparator rec ix_defItems ix_def ix_constr ix csr =
  rec.separator
    ix_defItems
    ix_def
    ix_constr
    ix
    (checkCursorHere csr)

-- TODO: if necessary
{-
type RecDefinitionBindings a
  = RecMetaContext.RecDefinitionBindings
      ( UpwardIndex -> -- definition
        UpwardIndex -> -- type
        Cursor -> -- type 
        UpwardIndex -> -- term
        Cursor -> -- term
        a
      )

type RecDefinitionBindings_ArrowLambda a
  = RecMetaContext.RecDefinitionBindings_ArrowLambda
      ( UpwardIndex -> -- definition
        UpwardIndex -> -- type
        Boolean -> -- type
        UpwardIndex -> -- term
        Boolean -> -- term
        UpwardIndex -> -- parameter
        Cursor -> -- parameter
        UpwardIndex -> -- type (sub)
        Cursor -> -- type (sub)
        UpwardIndex -> -- termId
        Cursor -> -- termId
        UpwardIndex -> -- block
        Cursor -> -- block
        a
      )

type RecDefinitionBindings_Wildcard a
  = RecMetaContext.RecDefinitionBindings_Wildcard
      ( UpwardIndex ->
        UpwardIndex ->
        Boolean ->
        UpwardIndex ->
        Boolean -> a
      )

recDefinitionBindings ::
  forall a.
  { arrow_lambda :: RecDefinitionBindings_ArrowLambda a
  , wildcard :: RecDefinitionBindings_Wildcard a
  } ->
  RecDefinitionBindings a
recDefinitionBindings rec =
  RecMetaContext.recDefinitionBindings
    { arrow_lambda:
        \prm beta termId block meta gamma metaGamma ix_def ix_type csr_type ix_term csr_term ->
          rec.arrow_lambda prm beta termId block meta gamma metaGamma
            -- def
            ix_def
            -- type
            ix_type
            csr_type
            -- term
            ix_term
            csr_term
            -- prm
            (ix_type :- ArrowType_Parameter)
            (checkCursorStep ArrowType_Parameter ?csr_type)
            -- beta
            (ix_type :- ArrowType_Type)
            (checkCursorStep ArrowType_Type ?csr_type)
            -- termId
            (ix_term :- LambdaTerm_TermId)
            (checkCursorStep LambdaTerm_TermId ?csr_term)
            -- block
            (ix_term :- LambdaTerm_Block)
            (checkCursorStep LambdaTerm_Block ?csr_term)
    , wildcard:
        \alpha a gamma metaGamma ix_def ix_alpha csr_alpha ix_a csr_a ->
          rec.wildcard alpha a gamma metaGamma
            -- def
            ix_def
            -- alpha
            ix_alpha
            (checkCursorHere csr_alpha)
            -- a 
            ix_a
            (checkCursorHere csr_a)
    }
-}
type RecType a
  = RecMetaContext.RecType (UpwardIndex -> Cursor -> a)

type RecType_Arrow a
  = RecMetaContext.RecType_Arrow
      ( UpwardIndex -> -- type
        Boolean -> -- type
        UpwardIndex -> -- parameter
        Cursor -> -- parameter
        UpwardIndex -> -- type (sub)
        Cursor -> -- type (sub)
        a
      )

type RecType_Data a
  = RecMetaContext.RecType_Data
      ( UpwardIndex -> -- type
        Boolean -> -- type
        a
      )

type RecType_Hole a
  = RecMetaContext.RecType_Hole
      ( UpwardIndex -> -- type
        Boolean -> -- type
        a
      )

type RecType_ProxyHole a
  = RecMetaContext.RecType_ProxyHole
      ( UpwardIndex -> -- type
        Boolean -> -- type
        a
      )

recType ::
  forall a.
  { arrow :: RecType_Arrow a
  , data :: RecType_Data a
  , hole :: RecType_Hole a
  , proxyHole :: RecType_ProxyHole a
  } ->
  RecType a
recType rec =
  RecMetaContext.recType
    { arrow:
        \prm beta meta gamma metaGamma ix csr ->
          rec.arrow prm beta meta gamma metaGamma
            -- type
            ix
            (checkCursorHere csr)
            -- prm
            (ix :- IndexStep StepArrowType 0)
            (checkCursorStep (IndexStep StepArrowType 0) csr)
            -- beta
            (ix :- IndexStep StepArrowType 1)
            (checkCursorStep (IndexStep StepArrowType 1) csr)
    , data: \typeId meta gamma metaGamma ix csr -> rec.data typeId meta gamma metaGamma ix (checkCursorHere csr)
    , hole: \holeID wkn meta gamma metaGamma ix csr -> rec.hole holeID wkn meta gamma metaGamma ix (checkCursorHere csr)
    , proxyHole: \holeID gamma metaGamma ix csr -> rec.proxyHole holeID gamma metaGamma ix (checkCursorHere csr)
    }

type RecTerm a
  = RecMetaContext.RecTerm (UpwardIndex -> Cursor -> a)

type RecTerm_Lambda a
  = RecMetaContext.RecTerm_Lambda
      ( UpwardIndex -> -- term
        Boolean -> -- term
        UpwardIndex -> -- termId
        Cursor -> -- termId
        UpwardIndex -> -- block
        Cursor -> -- block
        a
      )

type RecTerm_Neutral a
  = RecMetaContext.RecTerm_Neutral
      ( UpwardIndex -> -- term
        Boolean -> -- term
        UpwardIndex -> -- termId
        Cursor -> -- termId
        UpwardIndex -> -- argItems
        Cursor -> -- argItems
        a
      )

type RecTerm_Match a
  = RecMetaContext.RecTerm_Match
      ( UpwardIndex -> -- term
        Boolean -> -- term
        UpwardIndex -> -- term (sub)
        Cursor -> -- term (sub)
        (Int -> UpwardIndex) -> -- caseItems
        (Int -> Cursor) -> -- caseItems
        a
      )

type RecTerm_Hole a
  = RecMetaContext.RecTerm_Hole
      ( UpwardIndex -> -- term
        Boolean -> -- term
        a
      )

recTerm ::
  forall a.
  { lambda :: RecTerm_Lambda a
  , neutral :: RecTerm_Neutral a
  , match :: RecTerm_Match a
  , hole :: RecTerm_Hole a
  } ->
  RecTerm a
recTerm rec =
  RecMetaContext.recTerm
    { lambda:
        \termId block meta gamma prm beta metaGamma ix csr ->
          rec.lambda termId block meta gamma prm beta metaGamma
            -- term
            ix
            (checkCursorHere csr)
            -- termId
            (ix :- IndexStep StepLambdaTerm 0)
            (checkCursorStep (IndexStep StepLambdaTerm 0) csr)
            -- block
            (ix :- IndexStep StepLambdaTerm 1)
            (checkCursorStep (IndexStep StepLambdaTerm 1) csr)
    , neutral:
        \termId argItems meta gamma alpha metaGamma ix csr ->
          rec.neutral termId argItems meta gamma alpha metaGamma
            -- term
            ix
            (checkCursorHere csr)
            -- termId
            (ix :- IndexStep StepNeutralTerm 0)
            (checkCursorStep (IndexStep StepNeutralTerm 0) csr)
            -- argItems
            (ix :- IndexStep StepNeutralTerm 1)
            (checkCursorStep (IndexStep StepNeutralTerm 1) csr)
    , match:
        \typeId a cases meta gamma alpha metaGamma constrIDs ix csr ->
          rec.match typeId a cases meta gamma alpha metaGamma constrIDs
            -- term
            ix
            (checkCursorHere csr)
            -- term (sub)
            (ix :- IndexStep StepMatchTerm 0)
            (checkCursorStep (IndexStep StepMatchTerm 0) csr)
            -- caseItems
            (\i -> ix <> singletonUpwardIndex (IndexStep StepMatchTerm 1) <> fromListIndexToUpwardIndex i <> singletonUpwardIndex (IndexStep StepCaseItem 0))
            (\i -> checkCursorSteps (singletonDownwardIndex (IndexStep StepMatchTerm 1) <> fromListIndexToDownwardIndex i <> singletonDownwardIndex (IndexStep StepCaseItem 0)) csr)
    , hole:
        \meta gamma alpha metaGamma ix csr ->
          rec.hole meta gamma alpha metaGamma ix (checkCursorHere csr)
    }

type RecArgItems a
  = RecMetaContext.RecArgItems (UpwardIndex -> Cursor -> a)

type RecArgItems_Nil (a :: Prim.Type)
  = RecMetaContext.RecArgItems_Nil a

type RecArgItems_Cons a
  = RecMetaContext.RecArgItems_Cons
      ( UpwardIndex -> -- term
        Cursor -> -- term
        UpwardIndex -> -- argItems
        Cursor -> -- argItems
        a
      )

recArgItems ::
  forall a.
  { nil :: RecArgItems_Nil a
  , cons :: RecArgItems_Cons a
  } ->
  RecArgItems a
recArgItems rec =
  RecMetaContext.recArgItems
    { nil:
        \gamma alpha metaGamma ix csr ->
          rec.nil gamma alpha metaGamma
    , cons:
        \argItem argItems gamma prm beta metaGamma ix csr ->
          rec.cons argItem argItems gamma prm beta metaGamma
            -- term
            (ix :- IndexStep StepCons 0)
            (checkCursorStep (IndexStep StepCons 0) csr)
            -- argItems (sub)
            (ix :- IndexStep StepCons 1)
            (checkCursorStep (IndexStep StepCons 1) csr)
    }

type RecCase a
  = RecMetaContext.RecCase
      ( UpwardIndex -> -- match
        UpwardIndex -> -- case
        Cursor -> -- case
        a
      )

type RecCase_Case a
  = RecMetaContext.RecCase_Case
      ( UpwardIndex -> -- match
        UpwardIndex -> -- case
        Boolean -> -- case
        (Int -> UpwardIndex) -> -- termIdItem
        (Int -> Cursor) -> -- termIdItem
        UpwardIndex -> -- term
        Cursor -> -- term 
        a
      )

recCase ::
  forall a.
  { case_ :: RecCase_Case a } ->
  RecCase a
recCase rec =
  RecMetaContext.recCase
    { case_:
        \termIds block meta typeId constrId gamma alpha metaGamma ix_match ix csr ->
          rec.case_ termIds block meta typeId constrId gamma alpha metaGamma
            -- match
            ix_match
            -- case 
            ix
            (checkCursorHere csr)
            -- termIdItems
            (\i -> ix <> singletonUpwardIndex (IndexStep StepCase 1) <> fromListIndexToUpwardIndex i <> singletonUpwardIndex (IndexStep StepTermIdItem 0))
            (\i -> checkCursorSteps (singletonDownwardIndex (IndexStep StepCase 1) <> fromListIndexToDownwardIndex i <> singletonDownwardIndex (IndexStep StepTermIdItem 0)) csr)
            -- term
            (ix :- IndexStep StepCase 1)
            (checkCursorStep (IndexStep StepCase 1) csr)
    }

type RecParameter a
  = RecMetaContext.RecParameter (UpwardIndex -> Cursor -> a)

type RecParameter_Parameter a
  = RecMetaContext.RecParameter_Parameter
      ( UpwardIndex -> -- parameter
        Boolean -> -- parameter
        UpwardIndex -> -- type 
        Cursor -> -- type
        a
      )

recParameter ::
  forall a.
  { parameter :: RecParameter_Parameter a } ->
  RecParameter a
recParameter rec =
  RecMetaContext.recParameter
    { parameter:
        \alpha meta gamma metaGamma ix csr ->
          rec.parameter alpha meta gamma metaGamma
            -- parameter
            ix
            (checkCursorHere csr)
            -- type
            (ix :- IndexStep StepParameter 0)
            (checkCursorStep (IndexStep StepParameter 0) csr)
    }

type RecTypeBinding a
  = TypeBinding -> Context -> MetaContext -> UpwardIndex -> Cursor -> a

type RecTypeBinding_TypeBinding a
  = TypeId -> TypeBindingMetadata -> Context -> MetaContext -> UpwardIndex -> Boolean -> a

recTypeBinding ::
  forall a.
  { typeBinding :: RecTypeBinding_TypeBinding a
  } ->
  RecTypeBinding a
recTypeBinding rec (TypeBinding typeId meta) gamma metaGamma ix csr = rec.typeBinding typeId meta gamma metaGamma ix (checkCursorHere csr)

type RecTermBinding a
  = TermBinding -> Context -> MetaContext -> UpwardIndex -> Cursor -> a

type RecTermBinding_TermBinding a
  = TermId -> TermBindingMetadata -> Context -> MetaContext -> UpwardIndex -> Boolean -> a

recTermBinding ::
  forall a.
  { termBinding :: RecTermBinding_TermBinding a
  } ->
  RecTermBinding a
recTermBinding rec (TermBinding termId meta) gamma metaGamma ix csr = rec.termBinding termId meta gamma metaGamma ix (checkCursorHere csr)

type RecTermId a
  = TermId -> Context -> MetaContext -> UpwardIndex -> Cursor -> a

type RecTermId_TermId a
  = TermId -> Context -> MetaContext -> UpwardIndex -> Boolean -> a

recTermId :: forall a. { termId :: RecTermId_TermId a } -> RecTermId a
recTermId rec termId gamma metaGamma ix csr = rec.termId termId gamma metaGamma ix (checkCursorHere csr)
