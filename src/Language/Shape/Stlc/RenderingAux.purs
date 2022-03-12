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
import React as React
import React.DOM as DOM
import React.DOM.Props as Props
import Type.Proxy (Proxy(..))
import Unsafe as Unsafe

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
    DOM.span
      [ Props.className ("keyword " <> label) ]
      [ DOM.text label ]

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
      DOM.br'
    else
      DOM.span
        [ Props.className "punctuation" ]
        [ DOM.text label ]

intercalateHTML inter = DOM.span' <<< List.toUnfoldable <<< List.intercalate inter <<< map List.singleton

intersperseLeftHTML inter = DOM.span' <<< List.toUnfoldable <<< List.foldMap (\x -> inter <> (List.singleton x))

indent :: forall r. { indented :: Boolean | r } -> MetaContext -> React.ReactElement
indent { indented } metaGamma =
  if indented then
    DOM.span
      [ Props.className "indentation" ]
      $ [ punctuation.newline ]
      <> (Array.replicate metaGamma.indentation punctuation.indent)
  else
    DOM.span' []

indentOrSpace :: forall r. { indented :: Boolean | r } -> MetaContext -> React.ReactElement
indentOrSpace { indented } metaGamma =
  if indented then
    DOM.span
      [ Props.className "indentation" ]
      $ [ punctuation.newline ]
      <> (Array.replicate metaGamma.indentation punctuation.indent)
  else
    DOM.span' [ punctuation.space ]
