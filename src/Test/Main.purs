module Test.Main where

import Data.Tuple.Nested
import Language.Shape.Stlc.ChAtIndex
import Language.Shape.Stlc.Index
import Language.Shape.Stlc.Metadata
import Language.Shape.Stlc.Recursor.Action
import Language.Shape.Stlc.Syntax
import Language.Shape.Stlc.Types
import Prelude
import Data.Array (foldM)
import Data.Either (Either(..))
import Data.List (List(..), (:))
import Data.Map (Map)
import Data.Map.Unsafe as Map
import Data.Maybe (Maybe(..))
import Data.Set (fromFoldable)
import Data.Tuple (Tuple(..))
import Data.UUID as UUID
import Debug as Debug
import Effect (Effect)
import Language.Shape.Stlc.Changes (TypeChange(..))
import Undefined (undefined)
import Unsafe (fromJust)

main :: Effect Unit
main = do
  -- runHistory (Map.lookup' "enlambda in let impl" histories)
  runHistory (Map.lookup' "enArrow codomain" histories)

runHistory :: History -> Effect Unit
runHistory ((term /\ type_) /\ changes) = do
  let
    res =
      foldM
        ( \st change -> case applyChange change st of
            Just st' -> Right st'
            Nothing -> Left (st /\ change)
        )
        { term, type_, ix: nilIxDown, history: (term /\ type_) /\ [] }
        changes
  case res of
    Right _st -> do
      Debug.traceM $ "===[ runHistory success ]==="
    Left (st /\ change) -> do
      Debug.traceM $ "===[ runHistory failure ]==="
      Debug.traceM $ "===[ runHistory failure: last valid state ]==="
      Debug.traceM $ show st
      Debug.traceM $ "===[ runHistory failure: last change attempted on last valid state ]==="
      Debug.traceM $ show change
  pure unit

histories :: Map String History
histories =
  Map.fromFoldable
    [ "enlambda in let impl" /\ (Tuple (Tuple (Data { body: (Let { body: (Hole { meta: HoleMetadata {} }), impl: (Hole { meta: HoleMetadata {} }), meta: LetMetadata { indentBody: true, indentImpl: false, indentSign: false, name: Name Nothing }, sign: (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "115cef88-102b-4078-95b6-a096a9fa1573"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }), termBind: { meta: TermBindMetadata { name: Name (Just "x") }, termId: (TermId (fromJust (UUID.parseUUID "a544b42c-3186-4e53-9211-44d53464a058"))) } }), meta: DataMetadata { indentBody: false, indentSumItems: false, name: Name Nothing }, sumItems: ({ meta: SumItemMetadata { indented: false }, paramItems: Nil, termBind: { meta: TermBindMetadata { name: Name (Just "zero") }, termId: (TermId (fromJust (UUID.parseUUID "fa9f6650-6012-4369-bbbf-7e4af3607eb5"))) } } : { meta: SumItemMetadata { indented: false }, paramItems: ({ meta: ParamItemMetadata { indented: false }, type_: (DataType { meta: DataTypeMetadata {}, typeId: (TypeId (fromJust (UUID.parseUUID "f39f5e91-6b7f-4602-85f7-eef6f77f4971"))) }) } : Nil), termBind: { meta: TermBindMetadata { name: Name (Just "suc") }, termId: (TermId (fromJust (UUID.parseUUID "4bedc3b6-cbb9-4832-acc0-51e626e18573"))) } } : Nil), typeBind: { meta: TypeBindMetadata { name: Name (Just "Nat") }, typeId: (TypeId (fromJust (UUID.parseUUID "f39f5e91-6b7f-4602-85f7-eef6f77f4971"))) } }) (ArrowType { cod: (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "8bc4f498-39f0-41f3-8a3f-3a3bbcba8d53"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }), dom: (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "99fa7a94-b00d-4fe3-9a3e-353df412a769"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }), meta: ArrowTypeMetadata {} })) [ { ix: (IxDown ((IxStep IxStepData 2) : (IxStep IxStepLet 2) : Nil)), toReplace: (ReplaceTerm (Lam { body: (Hole { meta: HoleMetadata {} }), meta: LamMetadata { indentBody: false, name: Name Nothing }, termBind: { meta: TermBindMetadata { name: Name Nothing }, termId: (TermId (fromJust (UUID.parseUUID "757587ce-3f9a-4d1b-884e-2d7cd5de1e54"))) } }) (InsertArg (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "f1381897-f682-4c20-9ad3-c4d5d2256db8"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }))) } ])
    , "enArrow codomain" /\ (Tuple (Tuple (Data { body: (Let { body: (Hole { meta: HoleMetadata {} }), impl: (Hole { meta: HoleMetadata {} }), meta: LetMetadata { indentBody: false, indentImpl: false, indentSign: false, name: Name Nothing }, sign: (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "40130ea4-7be3-4bfc-9dcb-bc927a59a45e"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }), termBind: { meta: TermBindMetadata { name: Name (Just "x") }, termId: (TermId (fromJust (UUID.parseUUID "de8590cf-6303-4d28-b6c8-d64ee3bbeed3"))) } }), meta: DataMetadata { indentBody: false, indentSumItems: false, name: Name Nothing }, sumItems: ({ meta: SumItemMetadata { indented: false }, paramItems: Nil, termBind: { meta: TermBindMetadata { name: Name (Just "zero") }, termId: (TermId (fromJust (UUID.parseUUID "b758339b-2c4c-4d18-bbe2-d83b63663726"))) } } : { meta: SumItemMetadata { indented: false }, paramItems: ({ meta: ParamItemMetadata { indented: false }, type_: (DataType { meta: DataTypeMetadata {}, typeId: (TypeId (fromJust (UUID.parseUUID "479c9590-f9f9-494d-8768-501aafa985d2"))) }) } : Nil), termBind: { meta: TermBindMetadata { name: Name (Just "suc") }, termId: (TermId (fromJust (UUID.parseUUID "9229b08e-2d33-46ed-8e5a-270d10eeff5d"))) } } : Nil), typeBind: { meta: TypeBindMetadata { name: Name (Just "Nat") }, typeId: (TypeId (fromJust (UUID.parseUUID "479c9590-f9f9-494d-8768-501aafa985d2"))) } }) (ArrowType { cod: (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "be11d83f-05dc-4c59-bea7-5a101fdbd9aa"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }), dom: (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "465652fe-ca98-472d-ac82-a635074a4f79"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }), meta: ArrowTypeMetadata {} })) [ { ix: (IxDown ((IxStep IxStepData 2) : (IxStep IxStepLet 1) : Nil)), toReplace: (ReplaceType (ArrowType { cod: (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "40130ea4-7be3-4bfc-9dcb-bc927a59a45e"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }), dom: (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "a6de0178-5190-4388-94f2-eb7ef8a93a9e"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }), meta: ArrowTypeMetadata {} }) (InsertArg (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "a6de0178-5190-4388-94f2-eb7ef8a93a9e"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }))) }, { ix: (IxDown ((IxStep IxStepData 2) : (IxStep IxStepLet 1) : Nil)), toReplace: (ReplaceType (ArrowType { cod: (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "40130ea4-7be3-4bfc-9dcb-bc927a59a45e"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }), dom: (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "a6de0178-5190-4388-94f2-eb7ef8a93a9e"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }), meta: ArrowTypeMetadata {} }) (InsertArg (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "a6de0178-5190-4388-94f2-eb7ef8a93a9e"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }))) }, { ix: (IxDown ((IxStep IxStepData 2) : (IxStep IxStepLet 1) : (IxStep IxStepArrowType 1) : Nil)), toReplace: (ReplaceType (ArrowType { cod: (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "40130ea4-7be3-4bfc-9dcb-bc927a59a45e"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }), dom: (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "ee9c7e50-9194-48eb-938c-0b8053b0b29b"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }), meta: ArrowTypeMetadata {} }) (InsertArg (HoleType { holeId: (HoleId (fromJust (UUID.parseUUID "ee9c7e50-9194-48eb-938c-0b8053b0b29b"))), meta: HoleTypeMetadata {}, weakening: (fromFoldable []) }))) } ])
    ]
