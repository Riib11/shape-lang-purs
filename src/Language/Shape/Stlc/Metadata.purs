module Language.Shape.Stlc.Metadata where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.List (List)
import Data.Maybe (Maybe(..))
import Data.Show.Generic (genericShow)
import Data.String (codePointFromChar)
import Data.String as String
import Data.Symbol (class IsSymbol)
import Prim.Row (class Cons)
import Record as Record
import Type.Proxy (Proxy(..))
import Undefined (undefined)

_indented = Proxy :: Proxy "indented"
_hidden = Proxy :: Proxy "hidden"
_annotated = Proxy :: Proxy "annotated"

type ModuleMetadata = { hidden :: Boolean }
defaultModuleMetadata = { hidden: true } :: ModuleMetadata

type BlockMetadata = { indented::Boolean , hidden :: Boolean }
defaultBlockMetadata = { indented:false, hidden: false } :: BlockMetadata

type DefinitionItemMetadata = { indented::Boolean }
defaultDefinitionItemMetadata = {indented: true} :: DefinitionItemMetadata

type TermDefinitionMetadata = { indented::Boolean, hidden :: Boolean }
defaultTermDefinitionMetadata = { indented:false, hidden: false } :: TermDefinitionMetadata

type DataDefinitionMetadata = { hidden :: Boolean }
defaultDataDefinitionMetadata = { hidden: false } :: DataDefinitionMetadata

type ConstructorItemMetadata = {indented::Boolean}
defaultConstructorItemMetadata = {indented:false} :: ConstructorItemMetadata

type ConstructorMetadata = {}
defaultConstructorMetadata = {} :: ConstructorMetadata

type ParameterItemMetadata = {indented::Boolean}
defaultParameterItemMetadata = {indented:false} :: ParameterItemMetadata

type ArrowTypeMetadata = {}
defaultArrowTypeMetadata = {} :: ArrowTypeMetadata

type DataTypeMetadata = {}
defaultDataTypeMetadata = {} :: DataTypeMetadata

type HoleTypeMetadata = {}
defaultHoleTypeMetadata = {} :: HoleTypeMetadata

type LambdaTermMetadata = { annotated :: Boolean, indented :: Boolean }
defaultLambdaTermMetadata = { annotated: true, indented: false } :: LambdaTermMetadata

type ArgConsMetaData = { indented :: Boolean }
defaultArgConsMetaData = { indented : false } :: ArgConsMetaData

type NeutralTermMetadata = {}
defaultNeutralTermMetadata = {} :: NeutralTermMetadata

type ArgItemMetadata = {indented::Boolean}
defaultArgItemMetadata = {indented:false} :: ArgItemMetadata

type VariableTermMetadata =  {}
defaultVariableTermMetadata = {} :: VariableTermMetadata

type MatchTermMetadata = { indented :: Boolean }
defaultMatchTermMetadata = { indented: false } :: MatchTermMetadata

type CaseItemMetadata = {indented::Boolean}
defaultCaseItemMetadata = {indented:true} :: CaseItemMetadata

type TermIdItemMetadata = {indented::Boolean}
defaultTermIdItemMetadata = {indented:false} :: TermIdItemMetadata

type HoleTermMetadata = {}
defaultHoleTermMetadata = {} :: HoleTermMetadata

type CaseMetadata = {indented::Boolean}
defaultCaseMetadata = {indented:false} :: CaseMetadata

type ParameterMetadata = { name :: TermName }
defaultParameterMetadata = {name: TermName Nothing} :: ParameterMetadata

type TypeBindingMetadata = {name::TypeName}
defaultTypeBindingMetadata = {name:TypeName Nothing} :: TypeBindingMetadata

type TermBindingMetadata = {name::TermName}
defaultTermBindingMetadata = {name: TermName Nothing} :: TermBindingMetadata

data TypeName = TypeName (Maybe String)
data TermName = TermName (Maybe String)

-- instances for TypeName
derive instance Generic TypeName _
derive instance Eq TypeName
derive instance Ord TypeName

instance Show TypeName where
  show (TypeName (Just label)) = label
  show (TypeName Nothing) = "_"

readTermName :: String -> TermName 
readTermName str = 
  let str' = String.trim str in 
  if str' == "_" then 
    TermName Nothing 
  else 
    TermName (Just str')

readTypeName :: String -> TypeName
readTypeName str = 
  let str' = String.trim str in 
  if str' == "_" then 
    TypeName Nothing 
  else 
    TypeName (Just str')

-- instances for TermName
derive instance Generic TermName _
derive instance Eq TermName
derive instance Ord TermName

instance Show TermName where
  show (TermName (Just label)) = label
  show (TermName Nothing) = "_"


toggle :: forall label row' row. IsSymbol label => Cons label Boolean row' row => Proxy label -> Record row -> Record row 
toggle label = Record.modify label not 
