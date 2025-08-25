Please review all changes on the current branch using: `git diff main...HEAD`

If this is a large changeset, you can also do `git diff main...HEAD --stat` to get a list of files and use this to create a TODO list.

Once you've done this, please review all comments that were added or changed in teh code. Look for any comments that are unhelpful, redundant, or AI-generated slop that should be removed.

Comments we retain should either:
* Be a godoc comment for a function or package
* Clarify something that is not immediately clear in the code

Specifically, comments that were added to explain teh changes as it was being done, but do not contribute value to the code base long term, should be removed.
