{-# LANGUAGE NamedFieldPuns #-}
module Main where

import Control.Monad.IO.Class
import Data.Foldable
import Data.Maybe
import System.Console.Haskeline
import System.Directory
import System.FilePath
import System.Environment

import Language.Scheme

until_ :: Monad m => (a -> Bool) -> m a -> (a -> m ()) -> m ()
until_ pred prompt action = do
  result <- prompt
  if pred result
     then pure ()
     else action result >> until_ pred prompt action

schemeHistoryFile :: IO FilePath
schemeHistoryFile = do
  dataDir <- getAppUserDataDirectory "scheme"
  createDirectoryIfMissing True dataDir
  pure $ dataDir </> "scheme_history"

replLoop :: InputT IO ()
replLoop = do
    env <- liftIO newEnv
    liftIO $ loadStandardLibrary env
    until_ quitPred (getInputLine "Lisp>>> ") (evalAndPrint env . fromJust)
  where
    quitPred Nothing = True
    quitPred (Just "quit") = True
    quitPred _ = False

    evalAndPrint env str = do
      evalResult <- liftIO $ evalString env str
      case evalResult of
        Left  e     -> (outputStrLn . show) e
        Right exprs -> traverse_ (outputStrLn . show) exprs

runRepl :: IO ()
runRepl = do
  historyFile <- Just <$> schemeHistoryFile
  let settings = defaultSettings { historyFile }
  runInputT settings replLoop

main :: IO ()
main = do args <- getArgs
          if null args then runRepl else runOne $ args
