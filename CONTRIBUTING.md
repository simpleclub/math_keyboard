# Contributing guide

This file outlines how you can contribute to `math_keyboard`.  
If you are new to contributing on GitHub, you might want to see the setup section below. 

## Setting up your repo

### Fork the math_keyboard repository

* Ensure you have configured an SSH key with GitHub; see [GitHub's directions][ssh key].
* Fork [this repository][repo] using the "Fork" button in the upper right corner of the GitHub page.
* Clone the forked repo: `git clone git@github.com:<your_github_user_name>/math_keyboard.git`
* Navigate into the project: `cd math_keyboard`
* Add this repo as a remote repository: 
  `git remote add upstream git@github.com:simpleclub/math_keyboard.git`
   
### Create pull requests

* Fetch the latest repo state: `git fetch upstream`
* Create a feature branch: `git checkout upstream/master -b <name_of_your_branch>`
* Now, you can change the code necessary for your patch.

  Make sure that you bump the version in [`pubspec.yaml`][pubspec]. You **must** bump the Pubspec
  version when a new package version should be released and edit the [`CHANGELOG.md`][changelog]
  accordingly.  
  The version format needs to follow Dart's versioning conventions. See [this article][versioning]
  for everything you need to know about that. Pay special attention when landing breaking changes.
* Commit your changes: `git commit -am "<commit_message>"`
* Push your changes: `git push origin <name_of_your_branch>`

After having followed these steps, you are ready to [create a pull request][create pr].  
The GitHub interface makes this very easy by providing a button on your fork page that creates 
a pull request with changes from a recently pushed to branch.  
Alternatively, you can also use `git pull-request` via [GitHub hub][].

## Notes

* Always add tests or confirm that your code is working with current tests.
* Use `dart format . --fix` to format all code.
* Adhere to the lints, i.e. the warnings provided by Dart's linter based on the repo's lint rules.  
  Run `flutter analyze` in order to ensure that you are not missing any warnings or errors.
* If you find something that is fundamentally flawed, please propose a better solution - 
  we are open to complete revamps.

## Contributor License Agreement

We require contributors to sign our [Contributor License Agreement (CLA)][CLA].
In order for us to review and merge your code, please follow the link and sign the agreement.

[repo]: https://github.com/simpleclub/math_keyboard
[pubspec]: https://github.com/simpleclub/math_keyboard/blob/main/math_keyboard/pubspec.yaml
[changelog]: https://github.com/simpleclub/math_keyboard/blob/main/math_keyboard/CHANGELOG.md
[create pr]: https://help.github.com/en/articles/creating-a-pull-request-from-a-fork
[GitHub hub]: https://hub.github.com
[ssh key]: https://help.github.com/articles/generating-ssh-keys
[CLA]: https://cla-assistant.io/simpleclub/
[versioning]: https://stackoverflow.com/questions/66201337/how-do-dart-package-versions-work-how-should-i-version-my-flutter-plugins/66201338#66201338
