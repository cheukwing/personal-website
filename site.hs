--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Data.List              (isInfixOf)
import           Hakyll
import           System.FilePath.Posix  (takeBaseName,takeDirectory
                                         ,(</>),splitFileName)


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "files/*" $ do
        route idRoute
        compile copyFileCompiler

    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["education.md", "experience.md", "projects.md", "other.md"]) $ do
        route   $ niceRoute
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/information.html" defaultContext
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= removeIndexHtml
    
    match "about.md" $ do
        route   $ niceRoute
        compile $ getResourceBody
            >>= applyAsTemplate defaultContext
            >>= renderPandoc
            >>= loadAndApplyTemplate "templates/information.html" defaultContext
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= removeIndexHtml

    match "index.md" $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/landing.html" defaultContext
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= removeIndexHtml

    match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

-- replace a foo/bar.md by foo/bar/index.html
-- this way the url looks like: foo/bar in most browsers
-- from http://yannesposito.com/Scratch/en/blog/Hakyll-setup/
niceRoute :: Routes
niceRoute = 
    customRoute createIndexRoute
    where
        createIndexRoute ident = takeDirectory p </> takeBaseName p </> "index.html"
            where p = toFilePath ident

-- replace url of the form foo/bar/index.html by foo/bar
-- from http://yannesposito.com/Scratch/en/blog/Hakyll-setup/
removeIndexHtml :: Item String -> Compiler (Item String)
removeIndexHtml item = 
    return $ fmap (withUrls removeIndexStr) item
    where
        removeIndexStr :: String -> String
        removeIndexStr url = case splitFileName url of
            (dir, "index.html") | isLocal dir -> dir
            _                                 -> url
            where isLocal uri = not (isInfixOf "://" uri)