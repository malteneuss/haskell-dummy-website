{-# LANGUAGE OverloadedStrings, QuasiQuotes, TemplateHaskell, TypeFamilies #-}

module Main where
import Yesod

data App = App -- Put your config, database connection pool, etc. in here.

-- Derive routes and instances for App.
mkYesod "App" [parseRoutes|
/ HomeR GET
|]

instance Yesod App -- Methods in here can be overridden as needed.

-- The handler for the GET request at /, corresponds to HomeR.
getHomeR :: Handler Html
getHomeR = defaultLayout [whamlet|Hello Haskell!|]

main :: IO ()
main = warp 8081 App