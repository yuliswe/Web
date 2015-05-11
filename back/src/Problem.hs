module Problem where

import Happstack.Server
import Text.JSON as JSON
import DB
import Control.Monad.Trans (lift)

problemCollection :: IConnection c => c -> ServerPart Response
problemCollection conn = do
    current <- lookRead "current"
    perPage <- lookRead "perpage"
    result <- lift $ getAllProblems (Pagination current perPage) conn
    ok $ toResponse $ JSON.encode result

problemElement :: ServerPart Response
problemElement = do
    ok $ toResponse $ JSON.encode "test2"
    
    