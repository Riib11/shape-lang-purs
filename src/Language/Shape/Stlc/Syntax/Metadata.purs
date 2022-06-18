module Language.Shape.Stlc.Syntax.Metadata where

import Data.Tuple.Nested
import Language.Shape.Stlc.Index
import Language.Shape.Stlc.Metadata
import Language.Shape.Stlc.Syntax
import Language.Shape.Stlc.Syntax.Modify
import Prelude
import Data.Array as Array
import Data.List (List(..))
import Data.List as List
import Data.Maybe (Maybe(..), isNothing, maybe)
import Data.Newtype (over, unwrap, wrap)
import Debug as Debug
import Undefined (undefined)

indentSyntaxAt :: Maybe IxStep -> IxDown -> Syntax -> Maybe Syntax
indentSyntaxAt mb_step =
  modifySyntaxAt case _ of
    SyntaxTerm term -> pure <<< SyntaxTerm $ indentTerm mb_step term
    _ -> Nothing

indentTerm :: Maybe IxStep -> Term -> Term
indentTerm Nothing term = term

indentTerm (Just step) term =
  Debug.trace ("indentTerm " <> show step <> " " <> show term) \_ -> case term of
    Lam lam
      | step == ixStepLam.body -> Lam lam { meta = over LamMetadata (\o -> o { indentedBody = not o.indentedBody }) lam.meta }
    Let let_
      | step == ixStepLet.termBind -> Let let_
      | step == ixStepLet.sign -> Let let_ { meta = over LetMetadata (\o -> o { indentedSign = not o.indentedSign }) let_.meta }
      | step == ixStepLet.impl -> Let let_ { meta = over LetMetadata (\o -> o { indentedImpl = not o.indentedImpl }) let_.meta }
      | step == ixStepLet.body -> Let let_ { meta = over LetMetadata (\o -> o { indentedBody = not o.indentedBody }) let_.meta }
    Buf buf
      | step == ixStepBuf.sign -> Buf buf { meta = over BufMetadata (\o -> o { indentedSign = not o.indentedSign }) buf.meta }
      | step == ixStepBuf.impl -> Buf buf { meta = over BufMetadata (\o -> o { indentedImpl = not o.indentedImpl }) buf.meta }
      | step == ixStepBuf.body -> Buf buf { meta = over BufMetadata (\o -> o { indentedBody = not o.indentedBody }) buf.meta }
    Data data_
      | step == ixStepData.typeBind -> Data data_
      | step == ixStepData.sumItems -> Data data_ { meta = over DataMetadata (\o -> o { indentedSumItems = not o.indentedSumItems }) data_.meta }
      | step == ixStepData.body -> Data data_ { meta = over DataMetadata (\o -> o { indentedBody = not o.indentedBody }) data_.meta }
    Match match
      | step == ixStepMatch.term -> Match match
      | step == ixStepMatch.caseItems -> Match match { meta = over MatchMetadata (\o -> o { indentedCaseItems = not o.indentedCaseItems }) match.meta }
    _ -> term

stepUpToNearestIndentableParentIxUp :: IxUp -> Maybe IxStep /\ IxUp
stepUpToNearestIndentableParentIxUp ix = case List.uncons (unwrap ix) of
  Nothing -> Nothing /\ ix
  Just { head: step, tail: steps } ->
    if isIndentableIxStep step then
      Just step /\ wrap steps
    else
      stepUpToNearestIndentableParentIxUp (wrap steps)

isIndentableIxStep :: IxStep -> Boolean
isIndentableIxStep (IxStep lbl _) = lbl `Array.elem` indentableIxStepLabels
  where
  indentableIxStepLabels =
    [ IxStepArrowType, IxStepLam, IxStepLet, IxStepBuf, IxStepData, IxStepMatch, IxStepArgItem, IxStepSumItem, IxStepCaseItem, IxStepParamItem, IxStepTermBindItem, IxStepList
    ]

{-
modifySyntaxAt
  (\_ -> Just $ SyntaxTermBind $ args.termBind { meta = over TermBindMetadata (\meta -> meta { name = name' }) args.termBind.meta })
  (toIxDown ix)
  (SyntaxTerm st.term)
-}
replaceNameAt x toSyntax wrapMeta name' ix =
  modifySyntaxAt
    (\_ -> Just $ toSyntax $ x { meta = over wrapMeta (\meta -> meta { name = name' }) x.meta })
    ix
