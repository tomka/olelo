TODO
====

- Get rid of alias method chains
- Documentation
- Code comments and rdoc generation
- More specs/unit tests
- Captcha support
- Clean up stylesheet
- Support for branching operations (Maybe not that important for a gui?)
- Implement revert operation
- Syntax highlighting abstraction which use ultraviolet, coderay or pygments
- (DONE) Image support, Image gallery
- (DONE) More caching where it makes sense
- (DONE) Wiki installation under subpath (path_info translation could be done
  via rack middleware, generated links must be adapted)
- (DONE) Switch to grit maybe (grit does not support some things yet, but has native implementation of some git features)
- (DONE) Cache-control and etag support
- (DONE) Plugin system
- (DONE) Stackable output filters/engines
- (DONE) rubypants as filter, latex support as filter....
- (DONE) Create a larsch-creole gem
- (DONE) LaTeX integration
- (DONE) Problem with last modified dates, they always refer to the whole tree
- (DONE) Breadcrumbs for tree browsing
- (DONE) Automatic file extensions for wikitext files
- (DONE) Preview
- (DONE) Menu
- (DONE) Search
- (DONE) Edit uploaded files (overwrite)
- (DONE) Login
- (DONE) Editable user profile, change pw function
- (DONE, but could be a lot improved) RSS/Atom Changelog

Known bugs
----------

- Removed files have a next button for the last existing revision
  because the deletion is registered as commit for the respective file
  (see Page.next_commit)
- (WORKAROUND, no colspan used) Tablesorter doesn't get the colspan on /history
- If the page is too far in the past the next button does not work correctly
  (see Page.next_commit)
