module Language.Shape.Stlc.RenderingAux where

import Data.Homogeneous.Record
import Data.Tuple.Nested
import Language.Shape.Stlc.Recursion.Wrap
import Language.Shape.Stlc.Syntax
import Prelude
import Prim hiding (Type)
import Data.Array as Array
import Data.Foldable (class Foldable)
import Data.List as List
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Symbol (class IsSymbol)
import Data.Tuple as Tuple
import Language.Shape.Stlc.Recursion.MetaContext (MetaContext)
import Language.Shape.Stlc.Typing (Context)
import Prim.Row (class Cons)
import Type.Proxy (Proxy(..))
import Unsafe as Unsafe

{-
keyword :: _
keyword =
  fromHomogeneous $ (pure makeKeyword)
    <*> homogeneous
        { data_: "data"
        , match: "match"
        , with: "with"
        , let_: "let"
        , in_: "in"
        }
  where
  makeKeyword label =
    HH.span
      [ HP.class_ (HH.ClassName $ List.intercalate " " [ "keyword", label ]) ]
      [ HH.text label ]

punctuation :: _
punctuation =
  fromHomogeneous $ (pure makePunctuation)
    <*> homogeneous
        { period: "."
        , comma: ","
        , lparen: "("
        , rparen: ")"
        , alt: "|"
        , arrow: "->"
        , termdef: ":="
        , typedef: "::="
        , colon: ":"
        , mapsto: "=>"
        , space: " "
        , indent: "  "
        , newline: "\n"
        }
  where
  makePunctuation label =
    if label == "\n" then
      HH.br_
    else
      HH.span
        [ HP.class_ (HH.ClassName "punctuation") ]
        [ HH.text label ]

intercalateHTML inter = HH.span_ <<< List.toUnfoldable <<< List.intercalate inter <<< map List.singleton

intersperseLeftHTML inter = HH.span_ <<< List.toUnfoldable <<< List.foldMap (\x -> inter <> (List.singleton x))

indent :: forall r w i. { indented :: Boolean | r } -> MetaContext -> HH.HTML w i
indent { indented } metaGamma =
  if indented then
    HH.span
      [ HP.class_ (HH.ClassName "indentation") ]
      $ [ punctuation.newline ]
      <> (Array.replicate metaGamma.indentation punctuation.indent)
  else
    HH.span_ []

indentOrSpace :: forall r w i. { indented :: Boolean | r } -> MetaContext -> HH.HTML w i
indentOrSpace { indented } metaGamma =
  if indented then
    HH.span
      [ HP.class_ (HH.ClassName "indentation") ]
      $ [ punctuation.newline ]
      <> (Array.replicate metaGamma.indentation punctuation.indent)
  else
    HH.span_ [ punctuation.space ]
-}
