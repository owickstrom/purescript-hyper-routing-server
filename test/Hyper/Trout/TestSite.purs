module Hyper.Trout.TestSite where

import Prelude
import Data.Argonaut (class DecodeJson, class EncodeJson, decodeJson, jsonEmptyObject, (.:), (:=), (~>))
import Data.Either (Either(..))
import Data.Maybe (Maybe)
import Data.String (trim)
import Text.Smolder.HTML (h1)
import Text.Smolder.Markup (text)
import Type.Proxy (Proxy(..))
import Type.Trout (type (:/), type (:<|>), type (:=), type (:>), Capture, CaptureAll, Raw, ReqBody, Resource, QueryParam, QueryParams)
import Type.Trout.ContentType.HTML (HTML, class EncodeHTML)
import Type.Trout.ContentType.JSON (JSON)
import Type.Trout.Method (Delete, Get, Post)
import Type.Trout.PathPiece (class FromPathPiece, class ToPathPiece)

data Home = Home

instance encodeJsonHome :: EncodeJson Home where
  encodeJson Home = jsonEmptyObject

instance encodeHTMLHome :: EncodeHTML Home where
  encodeHTML Home = h1 (text "Home")

newtype UserID = UserID String

instance fromPathPieceUserID :: FromPathPiece UserID where
  fromPathPiece s =
    case trim s of
      "" -> Left "UserID must not be blank."
      s' -> Right (UserID s')

instance toPathPieceUserID :: ToPathPiece UserID where
  toPathPiece (UserID s) = s

data User = User UserID

instance encodeUser :: EncodeJson User where
  encodeJson (User (UserID userId)) =
    "userId" := userId
    ~> jsonEmptyObject

instance decodeUser :: DecodeJson User where
  decodeJson json = do
    obj <- decodeJson json
    userId <- UserID <$> obj .: "userId"
    pure $ User userId

data WikiPage = WikiPage String

instance encodeHTMLWikiPage :: EncodeHTML WikiPage where
  encodeHTML (WikiPage title) = text ("Viewing page: " <> title)

type UserResources =
  "profile" := "profile" :/ Resource (Get User JSON)
  :<|> "friends" := "friends" :/ Resource (Get (Array User) JSON :<|> Delete (Array User) JSON)
  :<|> "newFriend" := "friends" :/ ReqBody User JSON :> Resource (Post (Array User) JSON)

type TestSite =
  "home" := Resource (Get Home (HTML :<|> JSON))
  -- nested routes with capture
  :<|> "user" := "users" :/ Capture "user-id" UserID :> UserResources
  -- capture all
  :<|> "wiki" := "wiki" :/ CaptureAll "segments" String :> Resource (Get WikiPage HTML)
  -- query string parameters
  :<|> "search" := "search" :/ QueryParam "q" String :> Resource (Get (Maybe User) JSON)
  -- many query string parameters
  :<|> "searchMany" := "search-many" :/ QueryParams "q" String :> Resource (Get (Array User) JSON)
  -- raw middleware
  :<|> "about" := "about" :/ Raw "GET"

testSite :: Proxy TestSite
testSite = Proxy
