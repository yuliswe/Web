{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE FlexibleContexts #-}

module DB.Internal.Query where

import DB.Internal.Class
import Data.List
import Data.Maybe
import Database.HDBC    
import Control.Monad.Reader
import Control.Monad.Except

type WhereClause = String

data SaveQuery = SaveQuery {
    saveQuery :: String
} deriving (Show)
    
data GetQuery = GetQuery {
    getQuery :: String
} deriving (Show)

class SaveQueryC a where
    newSaveQuery :: String -> a
    getSaveQuery :: a -> String
    
    runSaveQuery :: a -> [SqlValue] -> ConnEither ID
    runSaveQuery a sqlvals =
        let f conn = ExceptT $ handleSql (return . Left . seErrorMsg) $ do 
                stmt <- prepare conn $ getSaveQuery a
                execute stmt sqlvals
                commit conn
                fmap (Right . fromSql . head . head) $ quickQuery conn "SELECT last_insert_rowid();" []
        in ReaderT f
        
    insertInto :: TableName -> [ColumnName] -> a
    insertInto tb cols = newSaveQuery $ "INSERT INTO " ++ tb ++ " (" ++ intercalate "," cols ++ ") VALUES (" ++ intercalate "," (map (\_ -> "?") cols) ++ ")"
    
    replaceInto :: TableName -> [ColumnName] -> a
    replaceInto tb cols = newSaveQuery $ "REPLACE INTO " ++ tb ++ " (" ++ intercalate "," cols ++ ") VALUES (" ++ intercalate "," (map (\_ -> "?") cols) ++ ")"
    
    
instance SaveQueryC SaveQuery where
    newSaveQuery = SaveQuery
    getSaveQuery = saveQuery
    
class GetQueryC a where
    newGetQuery :: String -> a
    getGetQuery :: a -> String
    
    runGetQuery :: a -> [SqlValue] -> ConnEither [[SqlValue]]
    runGetQuery a sqlVs =
        let f conn = ExceptT $ handleSql (return . Left . seErrorMsg) $ do 
                r <- quickQuery conn (getGetQuery a) sqlVs
                return $ Right r
        in ReaderT f
        
        
    selectID :: TableName -> [ColumnName] -> a
    selectID = selectWhere "idx = ?"
    
    selectPrev :: TableName -> [ColumnName] -> a
    selectPrev = selectWhere "idx < ? ORDER BY idx DESC LIMIT 1"
    
    selectNext :: TableName -> [ColumnName] -> a
    selectNext = selectWhere "idx > ? ORDER BY idx ASC LIMIT 1"
    
    selectWhere :: WhereClause -> TableName -> [ColumnName] -> a
    selectWhere clause = select $ " WHERE " ++ clause
    
    select :: String -> TableName -> [ColumnName] -> a
    select rst tb cols = newGetQuery $ "SELECT " ++ intercalate "," cols ++ " FROM " ++ tb ++ " " ++ rst
        
    selectP :: Pagination -> TableName -> [ColumnName] -> a
    selectP pag = select $ "LIMIT " ++ offset ++ ", " ++ top
        where
            curr   = fromJust $ current pag
            per    = fromJust $ perPage pag
            offset = show $ (curr - 1) * per
            top    = show $ per
        
    
instance GetQueryC GetQuery where
    newGetQuery = GetQuery
    getGetQuery = getQuery
    
