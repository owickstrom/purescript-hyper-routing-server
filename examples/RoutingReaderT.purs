module Examples.RoutingReaderT where

import Prelude
import Control.IxMonad ((:*>), (:>>=))
import Control.Monad.Aff (Aff)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Except (ExceptT)
import Control.Monad.Reader (ReaderT, ask, runReaderT)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Tuple (Tuple(..))
import Hyper.Conn (Conn)
import Hyper.Middleware.Class (getConn)
import Hyper.Node.BasicAuth as BasicAuth
import Hyper.Node.Server (defaultOptionsWithLogging, runServer')
import Hyper.Response (closeHeaders, respond, writeStatus)
import Hyper.Trout.Router (RoutingError, router)
import Node.Buffer (BUFFER)
import Node.HTTP (HTTP)
import Text.Smolder.HTML (p)
import Text.Smolder.Markup (text)
import Type.Proxy (Proxy(..))
import Type.Trout (type (:=), Resource)
import Type.Trout.ContentType.HTML (class EncodeHTML, HTML)
import Type.Trout.Method (Get)

data Greeting = Greeting String

type Site = "greeting" := Resource (Get Greeting HTML)

instance encodeHTMLGreeting :: EncodeHTML Greeting where
  encodeHTML (Greeting g) = p (text g)

runAppM ∷ ∀ e a. String -> ReaderT String (Aff e) a → (Aff e) a
runAppM = flip runReaderT

site :: Proxy Site
site = Proxy

greetingResource
  :: forall m req res t
   . Monad m
  => Show t
  => Conn req res { authentication :: Maybe t }
  -> {"GET" :: ExceptT RoutingError (ReaderT String m) Greeting}
greetingResource conn =
  {"GET": (Greeting <<< (flip append) (fromMaybe "Guest" (show <$> conn.components.authentication))) <$> ask}

data User = User String

instance showUser :: Show User where
  show (User name) = name

-- This could be a function checking the username/password in a database.
userFromBasicAuth :: forall e. Tuple String String -> ReaderT String (Aff e) (Maybe User)
userFromBasicAuth =
  case _ of
    Tuple "admin" "admin" -> pure (Just (User "Administrator"))
    _ -> pure Nothing

main :: forall e. Eff (buffer :: BUFFER, console :: CONSOLE, http :: HTTP | e) Unit
main =
  let app = BasicAuth.withAuthentication userFromBasicAuth
            :*> getConn :>>= \conn -> router site {"greeting": (greetingResource conn)} onRoutingError

      onRoutingError status msg =
        writeStatus status
        :*> closeHeaders
        :*> respond (fromMaybe "" msg)

  in runServer' defaultOptionsWithLogging { authentication: unit } (runAppM "Hello, ") app
