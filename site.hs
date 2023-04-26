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

    match ("education/*" .||. "experiences/*" .||. "projects/*" .||. "other/*") $ do
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/entry.html" defaultContext
            >>= removeIndexHtml

    match "about.md" $ do
        route   $ niceRoute
        compile $ toInformationPage defaultContext

    match "education.md" $ do
        route   $ niceRoute
        compile $ toInformationPage $ entryContext "education/*" "education"

    match "experience.md" $ do
        route   $ niceRoute
        compile $ toInformationPage $ entryContext "experiences/*" "experiences"

    match "projects.md" $ do
        route   $ niceRoute
        compile $ toInformationPage $ entryContext "projects/*" "projects"

    match "other.md" $ do
        route   $ niceRoute
        compile $ toInformationPage $ entryContext "other/*" "other"

    match "index.md" $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/landing.html" defaultContext
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= removeIndexHtml

    match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------

entryContext :: Pattern -> String -> Context String
entryContext dir name =
    listField name defaultContext (recentFirst =<< loadAll dir) `mappend` defaultContext

toInformationPage :: Context String -> Compiler (Item String)
toInformationPage ctx = 
    getResourceBody
        >>= applyAsTemplate ctx
        >>= renderPandoc
        >>= loadAndApplyTemplate "templates/information.html" ctx
        >>= loadAndApplyTemplate "templates/default.html" ctx
        >>= removeIndexHtml

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