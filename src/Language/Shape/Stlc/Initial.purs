module Language.Shape.Stlc.Initial where

import Data.List
import Data.Tuple.Nested
import Language.Shape.Stlc.Metadata
import Language.Shape.Stlc.Syntax
import Prelude
import Data.Maybe (Maybe(..))
import Data.Set as Set
import Effect (Effect)

makeTypeVar :: String -> TypeId /\ TypeName
makeTypeVar label = freshTypeId unit /\ TypeName (Just label)

makeTermVar :: String -> TermId /\ TermName
makeTermVar label = freshTermId unit /\ TermName (Just label)

module_ :: Module
module_ =
  let
    h1_id = freshHoleId unit

    h2_id = freshHoleId unit

    nat_id /\ nat_name = makeTypeVar "Nat"

    zero_id /\ zero_name = makeTermVar "zero"

    suc_id /\ suc_name = makeTermVar "suc"

    identity_id /\ identity_name = makeTermVar "identity"

    n_name = TermName (Just "n")

    a_id /\ a_name = makeTermVar "a"

    const_id /\ const_name = makeTermVar "const"

    x1_id /\ x1_name = makeTermVar "x"

    x2_id /\ x2_name = makeTermVar "x"

    tmp1_id /\ tmp1_name = makeTermVar "tmp1"

    x3_id /\ x3_name = makeTermVar "x"
  in
    Module
      ( fromFoldable
          [ DataDefinition (TypeBinding nat_id defaultTypeBindingMetadata { name = nat_name })
              ( fromFoldable
                  [ Constructor
                      (TermBinding zero_id defaultTermBindingMetadata { name = zero_name })
                      Nil
                      defaultConstructorMetadata
                      /\ defaultConstructorItemMetadata
                  , Constructor
                      (TermBinding suc_id defaultTermBindingMetadata { name = suc_name })
                      (fromFoldable [ Parameter (DataType nat_id defaultDataTypeMetadata) defaultParameterMetadata { name = n_name } /\ defaultParameterItemMetadata ])
                      defaultConstructorMetadata
                      /\ defaultConstructorItemMetadata
                  ]
              )
              defaultDataDefinitionMetadata
              /\ defaultDefinitionItemMetadata
          , TermDefinition
              (TermBinding identity_id defaultTermBindingMetadata { name = identity_name })
              ( ArrowType
                  (Parameter (DataType nat_id defaultDataTypeMetadata) defaultParameterMetadata { name = a_name })
                  (DataType nat_id defaultDataTypeMetadata)
                  defaultArrowTypeMetadata
              )
              ( LambdaTerm
                  a_id
                  ( Block Nil
                      (NeutralTerm a_id Nil defaultNeutralTermMetadata)
                      defaultBlockMetadata
                  )
                  defaultLambdaTermMetadata { indented = false }
              )
              defaultTermDefinitionMetadata
                { indented = false }
              /\ defaultDefinitionItemMetadata
          , TermDefinition
              (TermBinding const_id defaultTermBindingMetadata { name = const_name })
              ( ArrowType
                  (Parameter (DataType nat_id defaultDataTypeMetadata) defaultParameterMetadata { name = x1_name })
                  ( ArrowType
                      (Parameter (DataType nat_id defaultDataTypeMetadata) defaultParameterMetadata { name = x2_name })
                      (DataType nat_id defaultDataTypeMetadata)
                      defaultArrowTypeMetadata
                  )
                  defaultArrowTypeMetadata
              )
              ( LambdaTerm
                  x1_id
                  ( Block Nil
                      -- ( LambdaTerm x2_id
                      --     ( Block Nil
                      --         ( NeutralTerm x1_id Nil
                      --             defaultNeutralTermMetadata
                      --         )
                      --         defaultBlockMetadata
                      --     )
                      --     defaultLambdaTermMetadata { indented = true }
                      -- )
                      (HoleTerm defaultHoleTermMetadata)
                      defaultBlockMetadata
                  )
                  defaultLambdaTermMetadata
              )
              defaultTermDefinitionMetadata
              /\ defaultDefinitionItemMetadata
          , let
              identity'_id /\ identity'_name = makeTermVar "identity'"

              x_id /\ x_name = makeTermVar "x"

              x'_id /\ x'_name = makeTermVar "x'"
            in
              TermDefinition
                (TermBinding identity'_id defaultTermBindingMetadata { name = identity'_name })
                ( ArrowType
                    (Parameter (DataType nat_id defaultDataTypeMetadata) defaultParameterMetadata { name = x_name })
                    (DataType nat_id defaultDataTypeMetadata)
                    defaultArrowTypeMetadata
                )
                ( LambdaTerm
                    x_id
                    ( Block Nil
                        ( MatchTerm nat_id (NeutralTerm x_id Nil defaultNeutralTermMetadata)
                            ( fromFoldable
                                [ Case -- zero
                                    Nil
                                    (Block Nil (NeutralTerm zero_id Nil defaultNeutralTermMetadata) defaultBlockMetadata)
                                    defaultCaseMetadata
                                    /\ defaultCaseItemMetadata { indented = true }
                                , Case -- suc
                                    ((x'_id /\ defaultTermIdItemMetadata) : Nil)
                                    (Block Nil (NeutralTerm suc_id ((NeutralTerm x'_id Nil defaultNeutralTermMetadata /\ defaultArgItemMetadata) : Nil) defaultNeutralTermMetadata) defaultBlockMetadata)
                                    defaultCaseMetadata
                                    /\ defaultCaseItemMetadata { indented = true }
                                ]
                            )
                            defaultMatchTermMetadata
                        )
                        defaultBlockMetadata { indented = true }
                    )
                    defaultLambdaTermMetadata
                )
                defaultTermDefinitionMetadata
                /\ defaultDefinitionItemMetadata
          ]
      )
      defaultModuleMetadata
