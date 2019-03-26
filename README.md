
# A Pandoc-Based Layout Workflow for Scholarly Journals

This is a simple workflow for scholarly journals, for managing the preparation of multiple publication formats. It is based on the awesome [pandoc](http://pandoc.org) and, instead of messing around with XML, it relies on the pairing of markdown (for full-text) and YAML (for metadata).

The workflow is based on two conversions:

1. manuscripts from DOCX/ODT to markdown
2. manuscripts in markdown + YAML to galleys files (publication formats: HTML, PDF, XML, see [output](#output)) in one take

This is meant to happen on a shared folder, so that a single computer could be prepared for the proper conversions, while editors could work on their own machines.

Further considerations and a more in-depth description of the workflow are [available in this post](http://pierog.it/en/2018/03/markdown-workflow/).


## Disclaimer

It is currently experimental and build around the needs of open-access journals in the Humanities and Social Sciences. It is also influenced by the use of [_Open Journal Systems_](https://pkp.sfu.ca/ojs/), the publishing and managing platform (eg: the file name conventions, and the final HTML structure).

Unlike other more advanced systems --- and unlike other projects such as Scholarly Markdown --- this solution is dedicated to Editorial Teams that do receive papers in DOCX or ODT formats, and doesn't require authors to change their (_often bad_) habits.

_This is also my first approach to bash scripting._


## Dependencies

- [pandoc](http://pandoc.org/), version >2.0
- [TeX Live](https://www.tug.org/texlive/), tested with version 2017
- a Unix shell, for running scripts
- (optional) [ImageMagick](http://imagemagick.org/) is used for images optimization

Editors will only need a text editor in order to edit the markdown versions of the papers.


## Initial Setup

The working directory contains the following subdirectories:

- `./0-original/` where documents ready to be processed shall be placed
- `./1-layout/` where the markdown files will be edited
- `./2-publication/` where the publication files added will appear
- `./archive/` will contain past logs and backup files
- `./z-lib/` is the directory for configurations and templates.

The `./z-lib/` directory contains the template to generate the publication formats (`.latex` for PDF; `.html5` and `.css` for HTML; etc.). Three YAML files will be used for handling metadata and other configs:

- `article.yaml`: appended to each article for article-level metadata
- `issue.yaml`: for issue metadata
- `journal.yaml`: for journal metadata and general setup (eg: geometry for the PDF)


## Workflow

1. Manuscripts ready for layout (in DOCX or ODT file format) will be placed by editors in a directory named `./0-original/`.
2. The first conversion of manuscripts into markdown is carried from shell with `./fulltext-markdown.sh`. Converted manuscripts will be placed in the `./1-layout/` directory; an empty YAML for article-level metadata is prepended to each file.
3. Editors will then work in the `./1-layout/` directory, inserting metadata and other settings for each article, using YAML syntax. Editors will also fix the markdown syntax of each full-text
4. When needed, the second conversion of manuscripts from markdown into publication formats is possible from shell, with `./markdown-galleys.sh`. Generated files will be available in the `./2-publication/` directory.

The last two steps shall be repeated until happy with the results.

### markdown-galleys options

Currently the script for the conversion from markdown to publication files supports some options:

- `-h` or `--html` for the conversion to html format
- `-p` or `--pdf` for the conversion to pdf and TeX formats
- `-x` or `--xml` for the conversion to xml formats
- `-w` or `--word` for the conversion to docx format -- experimental
- `-b` or `--backup` will backup the current markdown files (find them in the archive), without any actual conversion

Options can be combined; if no option is specified, the script will generate all formats (with the exception of the word format, that is available only when the `--word` option is given). The `--backup` option will exclude any other option.

You can also specify the path of the files to be converted (one ore more); else the conversion will happen on every markdown file in `./1-layout/`.

Example:

```sh
$ ./markdown-galleys.sh -ph ./1-layout/demo-article.md
```

### Images

The first conversion will create subdirectories for media files inside `./1-layout/`. Media files may be processed using the shell, with `./img-compress.sh` (it must be launched inside the media directory). Each image will be scaled to optimal dimensions at 300DPI; a low resolution version, to be used in the HTML file, will also be generated.

Since the `--default-image-extension` of pandoc, editors should link images within the markdown file without extension --- except if it is different from the default (JPG) --- so that the low resolution version will be used when necessary.

### Backup and archive

Each conversion will generate an archive of backup copies and daily events logs, in order to secure the workflow. When works on an issue are closed, a complete archive of the working directory is available with `./archiver.sh`. The resulting zip will include also a copy of the setup files and of the scripts, along with a "self-contained" version of the markdown files, with the current config (in YAML) appended.


## Output

The resulting file formats are:

- HTML
	- HTML5
	- self-contained (one file with embedded a minimal CSS and images, if any)
	- metadata annotated in schema.org (with RDFa Lite)
	- functional Table of Contents and footnotes
	- low resolution images (72DPI)
- PDF
	- with XeLaTeX and Hyperref (functional Table of Contents and footnotes)
	- embedded fonts
	- optional first page with author's metadata
	- images at 300DPI
	- the TeX file for PDF triaging and editing
- (needs testing) JATS XML ([_Journal Article Tag Suite_](https://jats.nlm.nih.gov/))
- (needs testing) TEI XML ([_Text Encoding Initiative_](http://www.tei-c.org/index.xml))
- (experimental) DOCX

Several other file formats are possible due to the power of pandoc!


## Demo

You can see an example of the results:

`Demo Article.docx`, with revisions, comments, messy formatting etc. can be found in `0-original`

In `./1-layout/`:

- `demo_article.md`, the version of the docx as converted by pandoc and with the default yaml block;
- `demo_article-edited.md` is the same file after the required work (metadata was added in the yaml block; markdown syntax was fixed where necessary)
- in the directory `./demo_article-media/` you find the image in the file, as processed by the `img-compress.sh` script; the original image is available in `./orig/`

In `./2-publication/` you will find the publication files of `demo_article-edited.md`: the self-contained HTML galley; the PDF and its TeX file; a version in JATS XML format.

Please note that the references in this demo are embedded in the docx file, thus pandoc-citeproc is not used.
