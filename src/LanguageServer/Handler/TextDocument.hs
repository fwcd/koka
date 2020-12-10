-----------------------------------------------------------------------------
-- The LSP handlers that handle changes to the document
-----------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module LanguageServer.Handler.TextDocument( didOpenHandler
                                          , didChangeHandler
                                          , didSaveHandler
                                          , didCloseHandler
                                          ) where

import Common.Error                      ( checkError )
import Compiler.Compile                  ( compileModuleOrFile, Terminal (..) )
import Compiler.Options                  ( Flags )
import Control.Lens                      ( (^.) )
import Control.Monad.Trans               ( liftIO )
import qualified Data.Map                as M
import Data.Maybe                        ( fromJust )
import qualified Data.Text               as T
import Language.LSP.Diagnostics          ( partitionBySource )
import Language.LSP.Server               ( notificationHandler, publishDiagnostics, flushDiagnosticsBySource, sendNotification, Handlers )
import qualified Language.LSP.Types      as J
import qualified Language.LSP.Types.Lens as J
import LanguageServer.Conversions        ( toLspDiagnostics )
import LanguageServer.Monad              ( LSM, modifyLoaded )

didOpenHandler :: Flags -> Handlers LSM
didOpenHandler flags = notificationHandler J.STextDocumentDidOpen $ \not -> do
  let uri = not ^. J.params . J.textDocument . J.uri
  recompileFile flags uri

didChangeHandler :: Flags -> Handlers LSM
didChangeHandler flags = notificationHandler J.STextDocumentDidChange $ \_not -> do
  -- TODO: Recompile here for 'live' results, this requires using
  --       the VFS as described below in the 'recompileFile' function
  return ()

didSaveHandler :: Flags -> Handlers LSM
didSaveHandler flags = notificationHandler J.STextDocumentDidSave $ \not -> do
  let uri = not ^. J.params . J.textDocument . J.uri
  recompileFile flags uri

didCloseHandler :: Flags -> Handlers LSM
didCloseHandler flags = notificationHandler J.STextDocumentDidClose $ \_not -> do
  -- TODO: Remove file from LSM state?
  return ()

-- Recompiles the given file, stores the compilation result in LSM's state
-- and emits diagnostics.
recompileFile :: Flags -> J.Uri -> LSM ()
recompileFile flags uri = do
  let normUri = J.toNormalizedUri uri
      -- TODO: Handle error
      filePath = fromJust $ J.uriToFilePath uri

  -- TODO: Abstract the logging calls in a better way
  sendNotification J.SWindowLogMessage $ J.LogMessageParams J.MtInfo $ "Recompiling " <> T.pack filePath

  -- TODO: Use VFS to fetch the file's contents to provide
  --       'live' results as the user types
  loaded <- liftIO $ compileModuleOrFile terminal flags [] filePath False
  case checkError loaded of
    Right (l, _) -> do
      modifyLoaded $ M.insert normUri l
      sendNotification J.SWindowLogMessage $ J.LogMessageParams J.MtInfo $ "Successfully compiled " <> T.pack filePath
    Left _       -> return ()

  let diagSrc = T.pack "koka"
      diags = toLspDiagnostics diagSrc loaded
      diagsBySrc = partitionBySource diags
      maxDiags = 100
  if null diags
    then flushDiagnosticsBySource maxDiags (Just diagSrc)
    else publishDiagnostics maxDiags normUri (Just 0) diagsBySrc

-- TODO: Emit messages via LSP's logging mechanism
terminal :: Terminal
terminal = Terminal
  { termError = const $ return ()
  , termPhase = const $ return ()
  , termPhaseDoc = const $ return ()
  , termType = const $ return ()
  , termDoc = const $ return ()
  }