# Changelog

## 1.4.0 [Unreleased]

### Added

- Support for using the ``text`` property as a shortcut for ``markdown_text`` ([PR#19](https://github.com/daenvil/MarkdownLabel/pull/19) by [betalars](https://github.com/betalars) and [PR#20](https://github.com/daenvil/MarkdownLabel/pull/20), [#2](https://github.com/daenvil/MarkdownLabel/issues/2))
- Auto-translation when ``markdown_text`` is set to a localization key and the node is set to auto-translate ([PR#18](https://github.com/daenvil/MarkdownLabel/pull/18) by [betalars](https://github.com/betalars))
- Handling YAML/TOML front-matter when using the ``display_file()`` method. The ``get_frontmatter()`` method can be used afterwards to retrieve it ([#15](https://github.com/daenvil/MarkdownLabel/issues/15)).

### Changed

- Improved documentation
- The ``text`` property is no longer stored in scene files, avoiding redundant information

## 1.3.0 [2025-03-08]

### Added

- UID files for Godot 4.4+

## 1.2.1 [2025-01-17]

### Fixed

- icon.svg not scaling properly ([#13](https://github.com/daenvil/MarkdownLabel/issues/13))
- Header formats not updating properly in the editor ([#14](https://github.com/daenvil/MarkdownLabel/issues/14))

## 1.2.0 [2024-06-04]

### Added

- Customizable header colors ([PR#8](https://github.com/daenvil/MarkdownLabel/pull/8) by [halkeye](https://github.com/halkeye)):
  - Header levels have two new properties: ``override_font_color`` and ``font_color``. When ``override_font_color`` is ``true``, the headers will have its font color set to the ``font_color`` property. When ``override_font_color`` is false (default), headers will use the same font color as the rest of the text.
- Task list support ([#4](https://github.com/daenvil/MarkdownLabel/issues/4)):
  - Starting an unordered list item with ``[ ]`` or ``[x]`` will create a checkbox
  - The checkboxes are clickable by default and emit a signal when clicked. Their behavior and appearance can be customized
- Support for handling unhandled links ([#10](https://github.com/daenvil/MarkdownLabel/issues/10)):
  - The ``unhandled_link_clicked`` signal is emitted when the MarkdownLabel node does not handle a click on a link automatically
  - The ``assume_https_links`` property (default: ``true``) defines how unrecognized links are handled. If enabled, unrecognized links will be opened as HTTPS URLs (e.g. "example.com" will be opened as "https://example.com"). If disabled, unrecognized links will be left unhandled (emitting the ``unhandled_link_clicked`` signal). Ignored if ``automatic_links`` is disabled.
- Support for custom syntax ([#7](https://github.com/daenvil/MarkdownLabel/issues/7)):
  - Refactored the processing of all syntax elements into individual methods so they can be overridden if desired (``_process_text_formatting_syntax()``, ``_process_link_syntax()``, etc.)
  - Added two empty methods: ``_preprocess_line()`` and ``_process_custom_syntax()`` which can be overridden to insert custom syntax

### Fixed

- Fixed bug where a table could break all the following text

## 1.1.0 [2023-12-16]

### Added

- Implemented automatic handling of links:
  - Can be turned off with the ``automatic_links`` property
  - Valid URLs and mails are opened with user default settings
  - Headers are assigned an id following the same pattern as Github-flavored markdown. When clicked, links to that id make the label automatically scroll to their header ([#3](https://github.com/daenvil/MarkdownLabel/issues/3))

### Changed

- The ``bbcode_enabled`` and ``text`` properties are now hidden on the editor ([#1](https://github.com/daenvil/MarkdownLabel/issues/1)).

## 1.0.0 [2023-10-28]

- First released version