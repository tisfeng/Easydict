## Getting Started
We are using String Catalog in Xcode to manage translations for Easydict, so the following steps are what you need to get started on localizing the app.
#### Install Xcode 15+
You can install Xcode from the [Mac App Store](https://apps.apple.com/app/xcode/id497799835) or its beta versions on [Apple Developer](https://developer.apple.com/xcode/resources/).
#### Cloning and building the project
1. Use git to clone the project from GitHub to your Mac. You can do this by using the [git command line tool](https://docs.github.com/en/get-started/getting-started-with-git) or  [GitHub Desktop](https://desktop.github.com).
2. Open the project and build it, detailed instructions on how to build the project can be found [here](/README_EN.md#developer-build).
#### Add your language to String Catalog
Now you can start adding your own language!
1. Navigate to `Easydict -> Easydict -> App -> Localizable.xcstrings`. Also Expand `Main.storyboard` to find `Main.xcstrings (Strings)` These two `.xcstrings` files are what you are going to work on.
2. Click the `Localizable.xcstrings` file first and click the `+` button to find a list of available options. If you don't see the language you want to localize in the list (e.g. Canadian English). Scroll all the way down to the bottom of the menu to find `More Languages`.
3. After you add a language, you can start translating. Don't forget to translate the strings in `Main.xcstring (Strings)`😉
#### Previewing your translations
After you are done with your translations, it's nice to run the app and preview them to look for rooms for improvements. You can set the app language to the one that you did with a simple few clicks.
1. Find the Easydict icon on the top toolbar of Xcode and click on it
2. Click on `Edit Scheme...`
3. Select `RUN` tab on the left sidebar and choose `Options`
4. Scroll down and find `App Language`, then choose the one you localized for
5. Close the tab and use ⌘R to run the app and see your translations
#### Pushing your changes to GitHub
#### Additional Resources