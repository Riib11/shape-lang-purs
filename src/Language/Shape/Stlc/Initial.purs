module Language.Shape.Stlc.Initial where

import Data.Default
import Data.Tuple
import Data.Tuple.Nested
import Language.Shape.Stlc.Metadata
import Language.Shape.Stlc.Syntax
import Prelude
import Prim hiding (Type)
import Data.List.Unsafe (List(..))
import Data.List.Unsafe as List
import Data.Maybe (Maybe(..))
import Data.Newtype (over, wrap)
import Data.Set as Set
import Undefined (undefined)

mkTermVar :: String -> TermId /\ Name
mkTermVar str = freshTermId unit /\ Name (Just str)

mkTypeVar :: String -> TypeId /\ Name
mkTypeVar str = freshTypeId unit /\ Name (Just str)

init1 :: Term /\ Type
init1 =
  let
    natId /\ natName = mkTypeVar "Nat"

    zeroId /\ zeroName = mkTermVar "zero"

    sucId /\ sucName = mkTermVar "suc"
  in
    Data
      { typeBind: { typeId: natId, meta: default # over TypeBindMetadata (_ { name = natName }) }
      , sumItems:
          List.fromFoldable
            [ { termBind: { termId: zeroId, meta: default # over TermBindMetadata (_ { name = zeroName }) }
              , paramItems: List.fromFoldable []
              , meta: default
              }
            , { termBind: { termId: sucId, meta: default # over TermBindMetadata (_ { name = sucName }) }
              , paramItems: List.fromFoldable [ { type_: DataType { typeId: natId, meta: default }, meta: default } ]
              , meta: default
              }
            ]
      , body:
          let
            xId /\ xName = mkTermVar "x"
          in
            -- Lam
            --   { termBind: { termId: xId, meta: over TermBindMetadata (_ { name = xName }) default }
            --   , body:
            --       -- Neu { termId: xId, argItems: Nil, meta: default }
            --       Hole { meta: default }
            --   , meta: default
            --   }
            Let
              { termBind: { termId: xId, meta: over TermBindMetadata (_ { name = xName }) default }
              , sign: HoleType { holeId: freshHoleId unit, weakening: Set.empty, meta: default }
              , impl: Hole { meta: default }
              , body: Hole { meta: default }
              , meta: default
              }
      , meta: default
      }
      -- /\ ArrowType
      
      --     { dom: HoleType { holeId: freshHoleId unit, weakening: Set.empty, meta: default }
      
      --     , cod: HoleType { holeId: freshHoleId unit, weakening: Set.empty, meta: default }
      
      --     , meta: default
      
      --     }
      
      /\ HoleType { holeId: freshHoleId unit, weakening: Set.empty, meta: default }
