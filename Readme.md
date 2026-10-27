# discourse-emojis

A Discourse gem to provide all the necessary emoji data:

- emoji names
- toned emojis
- images for sets (noto, noto_animated, twemoji, openmoji, fluentui...)
- aliases
- search aliases
- groups

## Setup

You need to have [imagemagick](https://imagemagick.org/script/download.php) available on your system to run the rake task.

### imagemagick

On Debian or Ubuntu install:

```sh
sudo apt-get install -y imagemagick
```

On Fedora, CentOS or RHEL:

```sh
sudo yum install imagemagick
```

On macOS:

```sh
brew install imagemagick
```

The `noto_animated` set is a separate collection of 128 × 128 animated AVIFs, intended for larger animations rather than inline emoji replacements. It contains only available animations, with emoji names, skin tones, and aliases using `.avif` paths; there are no static fallbacks. The 861 images total approximately 41.7 MiB.

Regenerate it with `bundle exec rake emojis:noto_animated_emoji`. Generation downloads Google's 512 × 512 WebPs and requires Python 3 with Pillow 13.0.0 (`python3 -m pip install Pillow==13.0.0`) built with AVIF/libaom support. The encoder uses Lanczos resizing, AVIF quality 50, 4:4:4 color, and libaom speed 2. These settings were selected by comparing 14 presets on 15 varied emoji and inspecting image quality. Python and Pillow are only needed for regeneration; the gem ships the encoded assets.

## Updating the emojis

The process sadly involves multiple manual steps ATM as the remote sources can be very slow to download. Depending on what you want to update, you will have to update the files in vendor/ and/or the URLs in each set rake task (fluentui, noto, openmoji, twemoji...).

Once this is done, you should run the rake rask: `bundle exec rake emojis:generate`, this command should take few minutes. If the generated diff looks correct you can update the gem version and push the commit. The new gem version will be auto released. You now just have to update discourse.

## Current source of vendor files

### cldr-annotations.xml

This is used to generate the list of search aliases.

https://raw.githubusercontent.com/unicode-org/cldr/main/common/annotations/en.xml

### emoji-sequences.txt

This is used to list all the tonable emojis.

https://unicode.org/Public/emoji/17.0/emoji-sequences.txt (v17.0)

### emoji-test.txt

This is used to put the emojis in the correct groups.

https://unicode.org/Public/emoji/17.0/emoji-test.txt (v17.0)

### emoji-list.html

The local file is a save of the remote page without the extra files, just the html document as the images are hardcoded in base64. It's used to get all the images of the unicode standard without the emoji modifiers.

https://unicode.org/emoji/charts/full-emoji-list.html (v17.0)

### emoji-modifier-sequences.html

The local file is a save of the remote page without the extra files, just the html document as the images are hardcoded in base64. It's used to get all the images of the unicode standard for emoji modifiers.

https://unicode.org/emoji/charts/full-emoji-modifiers.html (v17.0)

## Future improvements

- we have a large emoji regex in core, which should be generated in this gem, atm you need to remember to update this regex when new emojis are released
- refactor unicode extractor, especially variations part
