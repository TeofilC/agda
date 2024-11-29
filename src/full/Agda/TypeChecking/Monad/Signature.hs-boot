{-# OPTIONS_GHC -Wunused-imports #-}

module Agda.TypeChecking.Monad.Signature where

import Control.Monad.Reader
import Control.Monad.State

import Agda.Syntax.Abstract.Name (QName)
import Agda.Syntax.Internal (ModuleName, Telescope)

import Agda.TypeChecking.Monad.Base
  ( TCM, TCMC, ReadTCState, HasOptions, MonadTCEnv
  , Definition, RewriteRules
  , CapIO
  )
import {-# SOURCE #-} Agda.TypeChecking.Monad.MetaVars (CapInteractionPoints)
import {-# SOURCE #-} Agda.TypeChecking.Monad.Debug (CapDebug, MonadDebug)

import Agda.Syntax.Common.Pretty (prettyShow)

data SigError = SigUnknown String | SigAbstract | SigCubicalNotErasure

notSoPrettySigCubicalNotErasure :: QName -> String

class ( Functor m
      , Applicative m
      , HasOptions m
      , MonadDebug m
      , MonadTCEnv m
      ) => HasConstInfo m where
  getConstInfo :: QName -> m Definition
  getConstInfo q = getConstInfo' q >>= \case
      Right d -> return d
      Left (SigUnknown err) -> __IMPOSSIBLE_VERBOSE__ err
      Left SigAbstract      -> __IMPOSSIBLE_VERBOSE__ $
        "Abstract, thus, not in scope: " ++ prettyShow q
      Left SigCubicalNotErasure -> __IMPOSSIBLE_VERBOSE__ $
        notSoPrettySigCubicalNotErasure q

  getConstInfo' :: QName -> m (Either SigError Definition)
  -- getConstInfo' q = Right <$> getConstInfo q
  getRewriteRulesFor :: QName -> m RewriteRules

  default getConstInfo' :: (HasConstInfo n, MonadTrans t, m ~ t n) => QName -> m (Either SigError Definition)
  getConstInfo' = lift . getConstInfo'

  default getRewriteRulesFor :: (HasConstInfo n, MonadTrans t, m ~ t n) => QName -> m RewriteRules
  getRewriteRulesFor = lift . getRewriteRulesFor

instance HasConstInfo m => HasConstInfo (ReaderT r m)
instance HasConstInfo m => HasConstInfo (StateT s m)

instance (CapIO c, CapDebug c, CapInteractionPoints c) => HasConstInfo (TCMC c) where

inFreshModuleIfFreeParams :: TCM a -> TCM a
lookupSection :: (Functor m, ReadTCState m) => ModuleName -> m Telescope
