# discourse-emojis

A Discourse gem to provide all the necessary emoji data:

- emoji names
- toned emojis
- images for sets (noto, twemoji, openmoji, fluentui...)
- aliases
- search aliases
- groups

## Updating the emojis

The process sadly involves multiple manual steps ATM as the remote sources can be very slow to download. Depending on what you want to update, you will have to update the files in vendor/ and/or the URLs in each set rake task (fluentui, noto, openmoji, twemoji...).

Once this is done, you should run the rake rask: `bundle exec rake generate`, this command should take few minutes. If the generated diff looks correct you can update the gem version and push the commit. The new gem verison will be auto released. You now just have to update discourse.

## Current source of vendor files

### cldr-annotations.xml

This is used to generate the list of search aliases.

https://raw.githubusercontent.com/unicode-org/cldr/main/common/annotations/en.xml

### emoji-sequences.txt

This is used to list all the tonable emojis.

https://unicode.org/Public/emoji/16.0/emoji-sequences.txt (v16.0)

### emoji-test.txt

This is used to put the emojis in the correct groups.

https://unicode.org/Public/emoji/16.0/emoji-test.txt (v16.0)

### emoji-list.html

The local file is a save of the remote page without the extra files, just the html document as the images are hardcoded in base64. It's used to get all the images of the unicode standard without the emoji modifiers.

https://unicode.org/emoji/charts/full-emoji-list.html (v16.0)

### emoji-modifier-sequences.html

The local file is a save of the remote page without the extra files, just the html document as the images are hardcoded in base64. It's used to get all the images of the unicode standard for emoji modifiers.

https://unicode.org/emoji/charts/full-emoji-modifiers.html (v16.0)
