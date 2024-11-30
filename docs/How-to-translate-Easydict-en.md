# Getting Started on Localization
Easydict uses Xcode String Catalog to manage translations, so the following steps are what you need to get started on localizing the app.
### Installing Xcode 15+
You can install Xcode from the [Mac App Store](https://apps.apple.com/app/xcode/id497799835) or its beta versions on [Apple Developer](https://developer.apple.com/xcode/resources/).
### Cloning and building the project
1. Use git to clone the project from GitHub to your Mac. You can do this by using the [git command line tool](https://docs.github.com/en/get-started/getting-started-with-git) or  [GitHub Desktop](https://desktop.github.com).
2. Make sure to base your changes on the [dev](https://github.com/tisfeng/Easydict/tree/dev) branch, this is where localization work takes place.
3. Open the project and build it, detailed instructions on how to build the project can be found [here](/README_EN.md#developer-build).
### Adding your language to String Catalog
Now you can start to add your own language!
1. Navigate to `Easydict -> Easydict -> App -> Localizable.xcstrings`. Also Expand `Main.storyboard` to find `Main.xcstrings (Strings)`. These two `.xcstrings` files are what you are going to work on.
2. Click on the `Localizable.xcstrings` file and click the `+` button to find a list of available options. If you don't see the language you want to localize on the list (e.g. Canadian English). Scroll all the way down to the bottom of the menu to find `More Languages`.
3. After you add a language, you can start translating. Don't forget to translate the strings in `Main.xcstring (Strings)`😉
### Previewing your translations
After you are done with your translations, it's nice to run the app and go over your work. You can set the app language to the one that you did with a simple few clicks.
1. Find Easydict's icon on the top toolbar of Xcode and click on it
2. Click on `Edit Scheme...`
3. Select the `RUN` tab on the left sidebar and go to `Options`
4. Scroll down to find `App Language`, then choose the one you localized for
5. Close the tab and use ⌘R to run the app and see your translations
### Pushing your changes to GitHub
After you finish checking your localization, it's time to push the changes to GitHub and start a pull request.
- [Start a Pull Request](https://docs.github.com/en/pull-requests).
- Remember to set the merge target to the `dev` branch

Now you can wait for a maintainer's review and get your translations adopted in the next release version.
### Additional Resources
- [Localization - Apple Developer](https://developer.apple.com/documentation/Xcode/localization)
- [Localizing and varying text with a string catalog - Apple Developer](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [Discover String Catalogs - WWDC23 Videos](https://developer.apple.com/videos/play/wwdc2023/10155)
- [Apple Localization Glossaries](https://applelocalization.com)
- [Sample Pull Request for Easydict](https://github.com/tisfeng/Easydict/pull/668)