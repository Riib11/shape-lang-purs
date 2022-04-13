module Language.Shape.Stlc.Changes where

import Data.Tuple.Nested
import Language.Shape.Stlc.Metadata
import Language.Shape.Stlc.Syntax
import Prelude
import Prim hiding (Type)

import Control.Monad.State (State, StateT, get, lift, put, runState, runStateT)
import Data.FoldableWithIndex (foldlWithIndex, foldrWithIndex)
import Data.Generic.Rep (class Generic)
import Data.List (List(..), concat, elem, filter, fold, foldl, foldr, mapMaybe, mapWithIndex, singleton, zip, zipWith, (:))
import Data.List.Unsafe (deleteAt', index', insertAt')
import Data.Map (Map, fromFoldable, insert, lookup, mapMaybeWithKey, toUnfoldable, union)
import Data.Map as Map
import Data.Map.Unsafe (lookup')
import Data.Maybe (Maybe(..))
import Data.Set (Set(..), difference, empty, member)
import Data.Show.Generic (genericShow)
import Data.Traversable (sequence)
import Data.Tuple (Tuple(..), fst, snd)
import Debug (trace)
import Debug as Debug
import Language.Shape.Stlc.Holes (HoleSub, emptyHoleSub, subType, unifyRestricted, unifyType)
import Language.Shape.Stlc.Recursion.Context as Rec
import Language.Shape.Stlc.Typing (Context, addDefinitionsToContext, insertTyping, lookupConstructorIds, lookupTyping)
import Undefined (undefined)
import Unsafe (error)

data TypeChange
    = ArrowCh TypeChange TypeChange -- only applies to types of form (ArrowType a b _)
    | NoChange
    | InsertArg Type
    | Swap -- only applies to types of form (ArrowType a (ArrowType b c _) _)
    | RemoveArg -- only applies to types of form (ArrowType a b _)
    -- | Replace Type -- can't allow Replace, because it would break the invariant that holesubs collected from chTerm can be applied at the end and never conflict with each other.
    | Dig HoleId
-- Note for the future: could e.g. make Swap take a typechange which says what happens to rest of type after swap. Currently, it is implicitly NoChange.

derive instance Generic TypeChange _
instance Show TypeChange where show x = genericShow x

data VarChange = VariableTypeChange TypeChange | VariableDeletion

data ParamChange = InsertParam Parameter | ChangeParam Int TypeChange
-- invariant assumption: the List ParamChange contains no duplicates,
-- e.g. if both (ChangeParam i c) and (ChangeParam j c') are in the list, then i =/= j.
data ConstructorChange = ChangeConstructor (List ParamChange) Int | InsertConstructor (List Parameter)

derive instance Generic VarChange _ 
instance Show VarChange where show x = genericShow x 

derive instance Generic ConstructorChange _ 
instance Show ConstructorChange where show x = genericShow x 

derive instance Generic ParamChange _ 
instance Show ParamChange where show x = genericShow x 

type Changes = {
    termChanges :: Map TermId VarChange,
    matchChanges :: Map TypeId (List ConstructorChange),
    dataTypeDeletions :: KindChanges
}

emptyChanges :: Changes
emptyChanges = {
    termChanges : Map.empty,
    matchChanges : Map.empty,
    dataTypeDeletions : empty
}

emptyDisplaced :: List Definition
emptyDisplaced = Nil

-- emptyDatatypeChange :: forall a. List a -> List ConstructorChange
-- emptyDatatypeChange = mapWithIndex (\index _ -> ChangeConstructor undefined index)

emptyParamsChange :: forall a. List a -> List ParamChange
emptyParamsChange = mapWithIndex (\index _ -> ChangeParam index NoChange)

deleteVar :: Changes -> TermId -> Changes
deleteVar {termChanges, matchChanges, dataTypeDeletions} i
    = {termChanges : insert i VariableDeletion termChanges, matchChanges, dataTypeDeletions}

varChange :: Changes -> TermId -> TypeChange -> Changes
varChange {termChanges, matchChanges, dataTypeDeletions} i ch
    = {termChanges : insert i (VariableTypeChange ch) termChanges, matchChanges, dataTypeDeletions}

type KindChanges = Set TypeId -- set of datatypes which have been deleted

applyTC :: TypeChange -> Type -> Type
applyTC (ArrowCh c1 c2) (ArrowType (Parameter a md1) b md2)
    = ArrowType (Parameter (applyTC c1 a) md1) (applyTC c2 b) md2
applyTC NoChange t = t
applyTC (InsertArg a) t = ArrowType (Parameter a defaultParameterMetadata) t defaultArrowTypeMetadata
applyTC Swap (ArrowType a (ArrowType b c md1) md2) = ArrowType b (ArrowType a c md1) md2
applyTC RemoveArg (ArrowType a b _) = b
applyTC (Dig id) t = HoleType id empty defaultHoleTypeMetadata
applyTC tc ty = error $ "Shouldn't get ehre. tc is: " <> show tc <> " ty is: " <> show ty

-- TODO: consider just outputting TypeChange, and then use chType : Type -> TypeChange -> Type to actually get the Type.
chType :: KindChanges -> Type -> Tuple Type TypeChange
chType chs (ArrowType (Parameter a pmd) b md)
    = let (Tuple a' ca) = chType chs a in
      let (Tuple b' cb) = chType chs b
      in Tuple (ArrowType (Parameter a' pmd) b' md) (ArrowCh ca cb)
chType chs (HoleType i w md)
    = Tuple (HoleType i (difference w chs) md) NoChange -- remove deleted datatypes from weakening -- TODO: is this how difference works?
chType chs (DataType i md) = if member i chs
    then let id = (freshHoleId unit)
        in Tuple (HoleType id empty defaultHoleTypeMetadata) (Dig id)
    else Tuple (DataType i md) NoChange
chType chs (ProxyHoleType i) = Tuple (ProxyHoleType i) NoChange

indexOf :: TermBinding -> TermId
indexOf (TermBinding i _) = i

-- (Map.insert id beta gamma)
cons :: TermBinding -> Type -> Context -> Context
cons (TermBinding i _) t ctx = insertTyping i t ctx

-- subContradict :: HoleSub -> HoleSub -> Boolean
-- subContradict sub1 sub2 = mapMaybeWithKey

-- If subs conflict, give error. Else, combine them.
-- This function is terrible
combineSubs :: HoleSub -> HoleSub -> HoleSub
-- combineSubs original new =
--     foldrWithIndex combineSub original new
--     where combineSub :: HoleId -> Type -> HoleSub -> HoleSub
--           combineSub id ty acc
--             = let ty' = subType acc ty in
--               case lookup id acc of
--                 Nothing -> insert id ty' acc
--                 Just tyAcc -> case unifyType ty' tyAcc of
--                     Nothing -> error "this breaks my assumption that unifications in chTerm should never result in ambiguous situations"
--                     Just secondarySubs -> combineSubs (insert id (subType secondarySubs ty') acc) secondarySubs
combineSubs _ _ = emptyHoleSub

chConstructor :: Context -> Changes -> Constructor -> State (Tuple (List Definition) HoleSub) Constructor
chConstructor ctx chs (Constructor binding params md) = do
    params' <- sequence $ map (\((Parameter t md1) /\ md2)
        -> do
              let (Tuple t' _) = chType chs.dataTypeDeletions t
              pure $ (Parameter t' md1) /\ md2) params
    pure $ Constructor binding params' md

chDefinition :: Context -> Changes -> Definition -> State (Tuple (List Definition) HoleSub) Definition
chDefinition ctx chs (TermDefinition binding ty t md)
    = let (Tuple ty' change) = chType chs.dataTypeDeletions ty
      in let chs' = varChange chs (indexOf binding) change
      in do
        t' <- chTerm ctx ty' chs' change t
        pure $ TermDefinition binding ty' t' md
chDefinition ctx chs (DataDefinition binding constrs md)
    = do constrs' <- sequence $ map (\(ctr /\ md)
        -> do ctr' <- chConstructor ctx chs ctr
              pure $ ctr' /\ md) constrs
         pure $ DataDefinition binding constrs' md

liiift :: forall a b c. State a c -> State (Tuple b a) c
liiift s = do (Tuple b a) <- get
              let (Tuple c a') = runState s a
              put (Tuple b a')
              pure c

split :: forall a b c . State (Tuple a b) c -> StateT a (State b) c
split s = do a <- get
             b <- lift get
             let (Tuple c (Tuple a b)) = runState s (Tuple a b)
             put a
             lift (put b)
             pure c

chTerm :: Context -> Type -> Changes -> TypeChange -> Term -> State (Tuple (List Definition) HoleSub) Term
chTerm ctx ty chs tc t = trace ("chTermCalled at " <> (show t) <> "\nwith type change " <> (show tc))
    (\_ -> chTermImpl ctx ty chs tc t)

-- morally, the type input here should not have metadata. But we can just go with it anyway.
chTermImpl :: Context -> Type -> Changes -> TypeChange -> Term -> State (Tuple (List Definition) HoleSub) Term
chTermImpl ctx ty chs (Dig _) t = pure $ HoleTerm defaultHoleTermMetadata
chTermImpl ctx (ArrowType (Parameter a _) b _) chs (ArrowCh c1 c2) (LambdaTerm binding block md)
    = do let (Tuple _ change) = chType chs.dataTypeDeletions a
        -- TODO: where to use change? This is indicative of a philosophical issue in how im thinking about this.
        -- TODO: TODO TODO TODO TODO TODO TODO TODO TODO
        -- TODO: TODO TODO TODO TODO TODO TODO TODO TODO
        -- TODO: TODO TODO TODO TODO TODO TODO TODO TODO
        -- TODO: TODO TODO TODO TODO TODO TODO TODO TODO
         block' <- liiift $ chBlock (insertTyping binding a ctx) b (varChange chs binding c1) c2 block
         pure $ LambdaTerm binding block' md
chTermImpl ctx (ArrowType (Parameter a _) b _) chs NoChange (LambdaTerm index block md)
    = do let (Tuple a' change) = chType chs.dataTypeDeletions a
         -- TODO TODO TODO TODO: also here and all the other cases with ArrowCh (or really function types at all)
         block' <- liiift $ chBlock (insertTyping index a ctx) b (varChange chs index change) NoChange block
         pure $ LambdaTerm index block' md
chTermImpl ctx ty chs (InsertArg a) t =
    -- do t' <- (chTerm ctx (ArrowType (Parameter a defaultParameterMetadata) ty defaultArrowTypeMetadata) chs NoChange t)
    do t' <- (chTerm ctx ty chs NoChange t)
       pure $ LambdaTerm newBinding (Block Nil t' defaultBlockMetadata) defaultLambdaTermMetadata
    where newBinding = (freshTermId unit)
chTermImpl ctx (ArrowType (Parameter a _) (ArrowType (Parameter b _) c _) _) chs Swap (LambdaTerm i1 (Block defs (LambdaTerm i2 (Block defs2 t md4) md1) md2) md3) =
    do let (Tuple a' change1) = (chType chs.dataTypeDeletions a)
       let (Tuple b' change2) = (chType chs.dataTypeDeletions b)
       let ctx' = (insertTyping i2 b' (insertTyping i1 a' ctx))
       let chs' = varChange (varChange chs i1 change1) i2 change2
       block <- liiift $ chBlock ctx' c chs' NoChange (Block (defs <> defs2) t md4)
       pure $ LambdaTerm i2 (Block Nil (LambdaTerm i1 block md3) md2) md1
chTermImpl ctx (ArrowType a b _ ) chs RemoveArg (LambdaTerm i (Block defs t md) _) =
      do displacedDefs <- sequence $ map (\(Tuple def _) -> chDefinition ctx (deleteVar chs i) def) defs
         displaceDefs displacedDefs
         chTerm ctx b (deleteVar chs i) NoChange t
chTermImpl ctx ty chs ch (NeutralTerm id args md) =
    case lookup id chs.termChanges of
        Just VariableDeletion -> do displaceArgs (lookupTyping id ctx) args
                                    pure $ HoleTerm defaultHoleTermMetadata
        Just (VariableTypeChange varTC) -> ifChanged varTC
        Nothing -> ifChanged NoChange
    where
    ifChanged varTC = do
        -- Debug.traceM $ "Calling chArgs from an id with type: " <> show (lookup' id ctx.types) <> " and typechange " <> show varTC
        (Tuple args' ch') <- chArgs ctx (lookupTyping id ctx) chs varTC args
        let _ = trace ("ch is " <> (show ch) <> " and ch' is " <> (show ch')) (\_ -> 5)
        let maybeSub = unifyRestricted (applyTC ch ty) (applyTC ch' ty)
        -- let maybeSub = Nothing -- TODO: should replace HoleSub with Map Holeid Holeid, and make version of unify to work with that
        let _ = trace ("resulting sub from that is " <> (show maybeSub)) (\_ -> 5)
        case maybeSub of
            Just holeSub -> do subHoles holeSub
                               pure $ NeutralTerm id args' md
            Nothing -> do displaceDefs (singleton (TermDefinition (TermBinding (freshTermId unit) defaultTermBindingMetadata) (applyTC ch' ty)
                                                        (NeutralTerm id args' md) defaultTermDefinitionMetadata))
                          pure $ HoleTerm defaultHoleTermMetadata
chTermImpl ctx ty chs ch (HoleTerm md) = pure $ HoleTerm md
chTermImpl ctx ty chs ch (MatchTerm i t cases md) = do -- TODO, IMPORTANT: Needs to deal with constructors being changed/added/removed and datatypes being deleted.
    cases' <- case lookup i chs.matchChanges of
        Nothing -> sequence $ (mapWithIndex (\index (cas@(Case ids _ _) /\ md)
            -> do cas' <- chCase2 cas i (index' (lookupConstructorIds i ctx) index) ctx ty chs (emptyParamsChange ids) ch --chCase ctx ty chs (emptyParamsChange ids) ch cas
                  pure $ cas' /\ md) cases)
        Just changes -> sequence $ (mapWithIndex (\index ctrCh
            -> case ctrCh of
               InsertConstructor params -> pure $ freshCase params
               ChangeConstructor pch n -> do cas' <- chCase2 (fst (index' cases n)) i (index' (lookupConstructorIds i ctx) index) ctx ty chs pch ch -- chCase ctx ty chs pch ch (fst (index' cases n))
                                             pure $ cas' /\ (snd (index' cases n))) changes)
    t' <- (chTerm ctx (DataType i defaultDataTypeMetadata) chs NoChange t)
    pure $ MatchTerm i t' cases' md
-- TODO: does this last case ever actually happen? I don't think it should.
chTermImpl ctx ty chs _ t -- anything that doesn't fit a pattern just goes into a hole
    = error "I dont think that this should happen"
    -- let (Tuple ty' change) = chType chs.dataTypeDeletions ty in
    -- do
    -- t' <- chTerm ctx ty chs change t -- is passing in ty correct? the type input to chTerm is the type of the term that is inputted?
    -- _ <- displaceDefs $ singleton (TermDefinition (TermBinding (freshTermId unit) defaultTermBindingMetadata) ty' t' defaultTermDefinitionMetadata)
    -- pure $ HoleTerm defaultHoleTermMetadata

freshCase :: forall a . List a -> CaseItem
freshCase params = Tuple (Case
    (map (\_ -> Tuple (freshTermId unit) defaultTermIdItemMetadata) params)
    (Block Nil (HoleTerm defaultHoleTermMetadata) defaultBlockMetadata)
    defaultCaseMetadata) defaultCaseItemMetadata

displaceDefs :: (List Definition) -> State (Tuple (List Definition) HoleSub) Unit
displaceDefs defs = do
    Tuple currDisplaced holeSub <- get
    put $ Tuple (currDisplaced <> defs) holeSub

subHoles :: HoleSub -> State (Tuple (List Definition) HoleSub) Unit
subHoles sub = do
    Tuple currDisplaced holeSub <- get
    put $ Tuple currDisplaced (combineSubs holeSub sub)


chCase2 :: Rec.RecCase (Changes -> (List ParamChange) -> TypeChange -> State (Tuple (List Definition) HoleSub) Case)
chCase2 = Rec.recCase {
    case_ : \bindings block meta dataTyId ctrId ctx ty chs paramChanges innerTC -> do
        let chs' :: Changes
            chs' = foldlWithIndex (\index chsAcc paramCh
            -> case paramCh of
                InsertParam t -> chsAcc
                ChangeParam i ch -> chsAcc{termChanges = insert (fst (index' bindings i)) (VariableTypeChange ch) chsAcc.termChanges})
                chs paramChanges
        let bindings' :: List TermIdItem
            bindings' = map (case _ of InsertParam _ -> freshTermId unit /\ defaultTermIdItemMetadata
                                       ChangeParam i _ -> index' bindings i) paramChanges
        let keptIndices = mapMaybe (case _ of InsertParam _ -> Nothing
                                              ChangeParam i _ -> Just i) paramChanges
        let toDelete :: List Int
            toDelete = filter (\i -> not (elem i keptIndices)) (mapWithIndex (\i _ -> i) bindings)
        let varsToDelete :: List TermId
            varsToDelete = map (\i -> fst (index' bindings i)) toDelete
        let chs'' = foldl (\chsAcc i -> chsAcc{termChanges = insert i VariableDeletion chsAcc.termChanges}) chs' varsToDelete
        -- TODO: need to add things to ctx

        block' <- liiift $ chBlock ctx ty chs'' innerTC block
        pure $ Case bindings' block' meta
}

-- data ParamsChange = DeleteParam Int | InsertParam Int Parameter | ChangeParam Int TypeChange | ParamsNoChange
-- The Type is type of term in the case excluding bindings
chCase :: Context -> Type -> Changes -> (List ParamChange) -> TypeChange -> Case -> State (Tuple (List Definition) HoleSub) Case
chCase ctx ty chs paramChanges innerTC (Case bindings t md) = do
    -- Int -> chs -> ParamChange -> chs
    let chs' :: Changes
        chs' = foldlWithIndex (\index chsAcc paramCh
        -> case paramCh of
            InsertParam t -> chsAcc
            ChangeParam i ch -> chsAcc{termChanges = insert (fst (index' bindings i)) (VariableTypeChange ch) chsAcc.termChanges})
            chs paramChanges
    let bindings' :: List TermIdItem
        bindings' = map (case _ of InsertParam _ -> freshTermId unit /\ defaultTermIdItemMetadata
                                   ChangeParam i _ -> index' bindings i) paramChanges
    let keptIndices = mapMaybe (case _ of InsertParam _ -> Nothing
                                          ChangeParam i _ -> Just i) paramChanges
    let toDelete :: List Int
        toDelete = filter (\i -> not (elem i keptIndices)) (mapWithIndex (\i _ -> i) bindings)
    let varsToDelete :: List TermId
        varsToDelete = map (\i -> fst (index' bindings i)) toDelete
    let chs'' = foldl (\chsAcc i -> chsAcc{termChanges = insert i VariableDeletion chsAcc.termChanges}) chs' varsToDelete
    -- TODO: need to add things to ctx

    t' <- liiift $ chBlock ctx ty chs'' innerTC t
    pure $ Case bindings' t' md


-- TODO: where was this supposed to be needed?
isNoChange :: TypeChange -> Boolean
isNoChange (ArrowCh c1 c2) = isNoChange c1 && isNoChange c2
isNoChange NoChange = true
isNoChange _ = false

chsToArrowCh :: List TypeChange -> TypeChange
chsToArrowCh Nil = NoChange
chsToArrowCh (Cons ch chs) = ArrowCh ch (chsToArrowCh chs)

-- State (Tuple (List Definition) HoleSub) Term
-- morally, shouldn't have the (List Definition) in the state of chBlock, as it always outputs the empty list.
chBlock :: Context -> Type -> Changes -> TypeChange -> Block -> State HoleSub Block
chBlock ctx ty chs ch (Block defs t md) = do
    let _ = trace ("calling chBlock with tc " <> (show ch)) (\_ -> 5) 
    let ctx' = addDefinitionsToContext (map fst defs) ctx
    let termDefs = mapMaybe (case _ of TermDefinition id ty te md /\ _ -> Just (Tuple id ty)
                                       DataDefinition id ctrs md /\ _ -> Nothing) defs
    let defChanges :: List (Tuple TermId TypeChange)
        defChanges = map (\(Tuple (TermBinding id _) ty) -> Tuple id $ snd (chType chs.dataTypeDeletions ty)) termDefs
    let dataDefs = mapMaybe (case _ of TermDefinition id ty te md /\ _ -> Nothing
                                       DataDefinition id ctrs md /\ _ -> Just (Tuple id ctrs)) defs
    let dataChanges :: List (Tuple TypeId (List (Tuple TermId (List TypeChange))))
        dataChanges = map (\(Tuple (TypeBinding id _) ctrs)
        -> Tuple id (map (\(Constructor (TermBinding cid _) params _ /\ _)
            -> Tuple cid (map (\(Parameter t _ /\ _) -> snd (chType chs.dataTypeDeletions t)) params)) ctrs)) dataDefs
    let constructorChangesTemp :: List (Tuple TermId (List TypeChange))
        constructorChangesTemp = concat (map snd dataChanges)
    -- let caseChanges :: List (Tuple TermId (List ParamChange))
    --     caseChanges = map (\(Tuple id pchs)
    --         -> Tuple id (mapWithIndex ChangeParam pchs)) constructorChangesTemp
    let constructorChanges :: List (Tuple TermId TypeChange)
        constructorChanges = map (\(Tuple id chList) -> Tuple id (chsToArrowCh chList)) constructorChangesTemp
    let newMatchChanges :: List (Tuple TypeId (List ConstructorChange))
        newMatchChanges = map (\(Tuple id ctrChs)
            -> Tuple id (mapWithIndex (\ix (Tuple _ chs) ->
                ChangeConstructor (mapWithIndex ChangeParam chs) ix) ctrChs)) dataChanges
    let newVarChanges :: List (Tuple TermId VarChange)
        newVarChanges = map (\(Tuple id tc) -> Tuple id (VariableTypeChange tc))
            (append defChanges constructorChanges)
    let chs' :: Changes
        chs' = chs{
                matchChanges = union chs.matchChanges (fromFoldable newMatchChanges),
                termChanges = union chs.termChanges (fromFoldable newVarChanges)
            }
    -- now, at long last I have the set of things whose types have changed in this block, chs'.
    -- Finally, need to call chDefinition, chData, and chTerm and collect all displaced things.
    defs' <- chDefList ctx' chs defs
    (t' /\ displaced) <- runStateT (split $ chTerm ctx' ty chs ch t) Nil
    let defs'' = defs' <> map (\def -> def /\ defaultDefinitionItemMetadata) displaced
    pure $ Block defs'' t' md

chDefList :: Context -> Changes -> (List DefinitionItem)
    -> State HoleSub (List DefinitionItem)
chDefList ctx chs Nil = pure $ Nil
chDefList ctx chs (Cons (def /\ md) rest) = do
    (def' /\ displaced) <- runStateT (split $ chDefinition ctx chs def) Nil
    rest' <- chDefList ctx chs rest
    pure $ (map (\def -> def /\ defaultDefinitionItemMetadata) displaced) <> Cons (def' /\ md) rest'
    

-- the Type is type of function which would input these args.
-- the TypeChange is the change of the function which inputs these arguments
chArgs :: Context -> Type -> Changes -> TypeChange -> List ArgItem
    -> State (Tuple (List Definition) HoleSub) (Tuple (List ArgItem) TypeChange)
chArgs ctx (ArrowType (Parameter a _) b _) chs RemoveArg (Cons (Tuple arg md) args) = do
    (Tuple args' chOut) <- chArgs ctx b chs NoChange args
    pure $ Tuple args' chOut -- note chOut should always be NoChange
chArgs ctx a chs (InsertArg t) args = do
    (Tuple rest chOut) <- chArgs ctx a chs NoChange args
    pure $ Tuple (Cons (Tuple (HoleTerm defaultHoleTermMetadata) defaultArgConsMetaData) rest) chOut -- always chOut = noChange
chArgs ctx (ArrowType (Parameter a _) b _) chs (ArrowCh c1 c2) (Cons (Tuple arg md) args) = do
    arg' <- chTerm ctx a chs c1 arg
    (Tuple args' tc) <- chArgs ctx b chs c2 args
    pure $ Tuple (Cons (Tuple arg' md) args') tc
chArgs ctx (ArrowType (Parameter a _) (ArrowType (Parameter b _) c _) _) chs Swap (Cons (Tuple arg1 md2) (Cons (Tuple arg2 md1) args)) = do
    arg1' <- chTerm ctx a chs NoChange arg1
    arg2' <- chTerm ctx b chs NoChange arg2
    (Tuple rest chOut) <- chArgs ctx c chs NoChange args
    pure $ Tuple (Cons (Tuple arg2' md2) (Cons (Tuple arg1' md1) rest)) chOut -- chOut = NoChange alwyas
chArgs ctx a chs ch Nil = pure $ Tuple Nil ch -- TODO: was there a reason that I wanted this to return only NoChange? Kind of defeats the point of using the result of chArgs in NeutralTerm case of chTerm!
chArgs ctx a chs ch Nil = if isNoChange ch then pure $ Tuple Nil ch else error "shoudln't get here 2"
chArgs ctx (ArrowType (Parameter a _) b _) chs NoChange (Cons (Tuple arg md) args) = do
    arg' <- chTerm ctx a chs NoChange arg
    (Tuple args' outCh) <- chArgs ctx b chs NoChange args
    pure $ Tuple (Cons (Tuple arg' md) args') outCh -- outCh = nochange
chArgs ctx ty chs (Dig hId) args = do
    displaceArgs ty args
    pure $ Tuple Nil (Dig hId)
chArgs _ ty _ ch args = error $ "shouldn't get here " <> (show ty) <> " and " <> (show ch) <> " and args is " <> (show args)

displaceArgs :: Type -> (List ArgItem) -> State (Tuple (List Definition) HoleSub) Unit
displaceArgs _ Nil = pure unit
displaceArgs (ArrowType (Parameter a _) b _) (Cons (arg /\ _) args) = do
    displaceDefs $ singleton $ TermDefinition (TermBinding (freshTermId unit)  defaultTermBindingMetadata)
        a arg defaultTermDefinitionMetadata
    displaceArgs b args
displaceArgs _ _ = error "no"

-- TODO: I've realized that "ctx" is wrong almost everywhere, I just autopilot filled it
-- in without thinking about when it needs to change.