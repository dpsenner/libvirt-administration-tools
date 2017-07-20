# Contributing

## Code of conduct

### Our pledge

In the interest of fostering an open and welcoming environment, we as contributors and maintainers pledge to making participation in our project and our community a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our standards

Examples of behavior that contributes to creating a positive environment include:

* Using welcoming and inclusive language
* Being respectful of differing viewpoints and experiences
* Gracefully accepting constructive criticism
* Focusing on what is best for the community
* Showing empathy towards each other

Examples of unacceptable behavior by participants include:

* The use of sexualized language or imagery and unwelcome sexual attention or advances
* Trolling, insulting/derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as physical or electronic address, without explicit permission
* Other conduct which could reasonably be considered inappropriate in a professional setting

### Our responsibilities

Project maintainers are responsible for clarifying the standards of acceptable behavior and are expected to take appropriate and fair corrective action in response to any instances of unacceptable behavior.

Project maintainers have the right and responsibility to remove, edit, or reject comments, commits, code, wiki edits, issues, and other contributions that are not aligned to this Code of Conduct, or to ban temporarily or permanently any contributor for other behaviors that they deem inappropriate, threatening, offensive, or harmful.

### Scope

This code of conduct applies both within project spaces and in public spaces when an individual is representing the project or its community. Examples of representing a project or community include using an official project e-mail address, posting via an official social media account, or acting as an appointed representative at an online or offline event. Representation of a project may be further defined and clarified by project maintainers.

### Attribution

This code of conduct is adapted from the Contributor Covenant, version 1.4, available [here](http://contributor-covenant.org/version/1/4).

## Patches

When contributing patches to this repository please think of yourself of being a story teller. Someone else is going to review your changes and will have to make a sense of it. If the reviewer has a story to read it helps a lot to put a meaning into all the modifications. On the other hand, if a story is complicated and is too hard to follow and understand, a reviewer will most likely give up reading it and simply refuse to apply the patches.

## Gitflow

This project uses gitflow, so please base all your modifications on the branch develop. If the modifications are large and will take a considerable amount of time, it could make sense to create a feature branch that branches from develop. This allows you to separate your modifications from future modifications in the develop branch.

The master branch is there to track the latest published codebase. Therefore master will most of the times be behind develop. Only things that are well tested and are ready for production should be merged into master. This is typically done by completing a release process.

A release process starts by creating a release branch. That release branch should be named by the version it targets to release prefixed with `release/`. To prepare the release of `v1.0`, the release branch would therefore be `release/v1.0`. It is only allowed to make release related modifications to the codebase in a release branch. Such modifications include:

* adapt version strings
* modify informational parts of the codebase like comments, documentation, readme, ..

When the codebase in a release branch is ready for the release, the head of that branch should be merged to master and be tagged with the released version.

Hotfixes branch from a tagged release on the master branch and when all the modifications are made, the release process starts like if it was the develop branch.

## Commits and commit messages

Each commit should be an atomar modification and the commit message is the story that explains the modification. A commit message should consist of at least one line that is the summary and explains the modifications. If you cannot write a short summary of the modification in one line with a maximum length of roughly 80 characters, there are too many changes in one commit and you should consider splitting those changes into multiple commits.

When one found typos in the README and fixes them, then this could be a good commit message:

```
README: fixed a few typos
```

When one does whitespace modifications in several submodules, then he would have to split those modifications into several commits, each of them having a commit message like:

```
Submodule1: removed trailing whitespaces
```

It can also be ok to group small changes into one iff the modifications are small enough:

```
Submodule2: removed a few trailing whitespaces and fixed one typo in a comment
```

Modifications that change functionality should be backed up with a story that explains those changes. In this case this could be a good commit message:

```
Backups: fixed backups to work on sundays

This patch improves a conditional expression to work also on Sundays. Until now
backups did not work on Sundays because there was a bad conditional expression
that caused the script to exit.
```

## Pull requests

Pull requests are typically a set of commits. As with commit messages, a pull request should have a one liner summary and a longer description explaining what the pull request is about, what it improves and how it improves. If possible, it is good to back it up with background information and considerations that the author had thought about but decided to do implement otherwise.

## Issues

Ideally, all modifications are backed up by an issue. However it is often not necessary to write an issue if the fix is already ready to be filed as a pull request and the issue would only reflect the same information from the pull request. Consider opening issues for things that are not trivial to fix and need discussion or things that you cannot fix by yourself. Please note however that if you need something to be done soon, your best bet is to do it yourself.

