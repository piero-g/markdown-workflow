
# A Pandoc-Based Layout Workflow for Scholarly Journals

_**Work in progress** (see also testing branch)_

This is a simple multiple-format layout workflow for scholarly journals. It is based on the awesome [pandoc](https://pandoc.org) and, instead of messing around with XML, it relies on the pairing of markdown (for full-text) and YAML (for metadata).

The workflow is based on two conversions:

1. manuscripts from DOCX/ODT/TEX to markdown+YAML
2. manuscripts in markdown+YAML to galleys files (publication formats: HTML, PDF, XML, see [output](#output)) in one take

The whole workflow is meant to happen on a shared folder, so that a single computer could be prepared for the proper conversions, while layout editors could work on their own machines.

Further considerations and a more in-depth description of the workflow are [available in this post](http://pierog.it/en/2018/03/markdown-workflow/) (currently outdated).


## Disclaimer

It is currently experimental and built around the needs of open-access journals in the Humanities and Social Sciences. It is also influenced by the use of [_Open Journal Systems_](https://pkp.sfu.ca/ojs/), the publishing and managing platform (eg: the file name conventions, and the final HTML structure).

Unlike other more advanced systems --- and unlike other projects such as Scholarly Markdown --- this solution is dedicated to Editorial Teams that do receive papers in DOCX or ODT formats, and doesn't require authors to change their (_often bad_) habits.

_This is also my first approach to bash scripting._


## Dependencies

- [pandoc](https://pandoc.org/), version >3.0
- [TeX Live](https://www.tug.org/texlive/), currently working with TeX Live 2020 (and transitioning to TeX Live 2023)
- a Bash shell, for running scripts
- (optional) [ImageMagick](https://imagemagick.org/) is used for images optimization (currently using ImageMagick 6.9)

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

1. Copyedited manuscripts that are ready for layout preparation (in DOCX, ODT or TEX file format) will be placed by editors in the directory named `./0-original/`.
2. The first conversion of manuscripts into markdown is carried from shell with [`./fulltext-markdown.sh`](#fulltext-markdown). Converted manuscripts will be placed in the `./1-layout/` directory; an empty YAML for article-level metadata is prepended to each file.
3. Editors will then work in the `./1-layout/` directory, inserting metadata and other settings for each article, using YAML syntax. Editors will also fix the markdown syntax of each full-text
4. When needed, the second conversion of manuscripts from markdown into publication formats is possible from shell, with [`./markdown-galleys.sh`](#markdown-galleys-options). Generated files will be available in the `./2-publication/` directory.

The last two steps shall be repeated until happy with the results.


### fulltext-markdown

This script converts ODT, DOCX, and TEX file to markdown format.
It looks for files in the directory `./0-original/` and it writes new MD files to `./1-layout/`.

It requires no argument.
It will archive original manuscripts (see [`./archive/`](#backup-and-archive)).

For suggested naming convention, see the documentation.  
_(ToDo: write documentation)_


### markdown-galleys

Currently the script for the conversion from markdown to publication files supports some options:

- `-h`, `--help`: display this message and exit
- `-H`, `--html`: convert only to HTML format
- `-p`, `--pdf`: convert only to PDF and TeX formats
- `-x`, `--xml`: convert only to JATS XML formats
- `-w`, `--word`: convert only to DOCX format -- experimental (useful for additional copyediting or antiplagiarism)
- `-b`, `--backup` will backup the current markdown files (find them in [./archive/layout-versions/](#backup-and-archive)), without any actual conversion

Options can be combined; if no option is specified, the script will generate all formats (with the exception of the word format, that is available only when the `--word` option is given). The `--backup` option will exclude any other option.

You can also specify the path of the files to be converted (one ore more); else the conversion will happen on every markdown file in `./1-layout/`.

Example:

```sh
$ ./markdown-galleys.sh -pH ./1-layout/demo-article.md
```

### Images

The first conversion will create subdirectories for media files inside `./1-layout/`. Media files may be processed using the shell, with `./img-compress.sh` (it must be launched inside the media directory). Each image will be scaled to optimal dimensions at 300DPI; a low resolution version, to be used in the HTML file, will also be generated.

Since the `--default-image-extension` of pandoc, editors should link images within the markdown file without extension --- except if it is different from the default (JPG) --- so that the low resolution version will be used when necessary.

The `./img-compress.sh` script must run inside each media folder, it will prepare the files.

The first conversion run should always be on all the images.
later you may perform actions on one or more images.
Accepted formats are jpg, png, tif.

The following options are supported:

- `-h`, `--help`: display this message and exit
- `-i`, `--identify`: print type, size, resolution (density) and colorspace
- `-l`, `--log`: save --identify or --density to imagelog
- `-p`, `--preserve`: don't convert PNG to JPG
- `-D`, `--density`: set only the given density to images, don't convert (use it with --dpi)
- `-d`, `--dpi`: set a different density parameter for images (default: 300)
- `-L`, `--lowres`: don't convert image, just recreate the low-res version
- `-w`, `--widthlow`: set a custom width for low-res version, useful with --lowres and to alter width and height (default: 800 with max height: 500px)


### Serial-editor

This script performs some serial edits to the YAML part of markdown files.
Each option should be launched separately.

The following options are supported:
- `-h`, `--help`: display this message and exit
- `-u`, `--undraft`: change "draft: true" to "false"
- `-p`, `--publication`: set the given publication date (specified in YYYY-MM-DD format)
- `-c`, `--countpages`: count the pages for each PDF in `./2-publication/`. The output can be copied and pasted as a TSV
- `-s`, `--pagesequence`: reads a TSV with id/filename, starting page, ending page and writes those data to `page.start` and `page.end`

### Status check

This script is to quickly check if the files in the working directory
have been updated. It will stamp a list of files for:

0-original/  
1-layout/  
2-publication/ [only the two most recent PDFs!]

It takes no arguments.


### Backup and archive

Each conversion will generate an archive of backup copies and daily events logs, in order to secure the workflow. When works on an issue are closed, a complete archive of the working directory is available with `./archiver.sh`. The resulting zip will include also a copy of the setup files and of the scripts, along with a "self-contained" version of the markdown files, with the current config (in YAML) appended.

#### Backup of the working directory

When working with multiple journals and editors, using a cloud service for file synchronization, you will probably have your working directory synced: it is a good idea to make a daily backup of the whole directory for each journal. This is optional and it is made via rsync. To enable it you must compile the `./z-lib/journal.conf` file: the parameters can accept only latin alphabet chars (A-Z and a-z), numbers (0-9), and the path can accept slashes. The conf file accepts comments only in a newline.

For example:

```
journal_shortname=demo
backup_path=/home/name/Backup/
```

The backup path must be absolute and will be combined with the `journal_shortname`; thus in this example the daily backup will happen in `~/Backup/demo/`. Please _double check_ your backup path before enabling this feature.

#### Archiving the working directory

This script is to archive the working directory after the issue is published.

It will also create a self-contained version of MD articles with metadata and settings. It takes no arguments.

It will prompt you to check for any leftovers (check `./archive/`!), and for the name of the zipped archive.

Please note that the ./archive/ itself wont be emptied.


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

Several other file formats are possible thanks to the power of pandoc!


## Demo

You can see an example of the results:

`Demo Article.docx`, with revisions, comments, messy formatting etc. can be found in `0-original`

In `./1-layout/`:

- `demo_article.md`, the version of the docx as converted by pandoc and with the default yaml block;
- `demo_article-edited.md` is the same file after the required work (metadata was added in the yaml block; markdown syntax was fixed where necessary)
- in the directory `./demo_article-media/` you find the image in the file, as processed by the `img-compress.sh` script; the original image is available in `./orig/`

In `./2-publication/` you will find the publication files of `demo_article-edited.md`: the self-contained HTML galley; the PDF and its TeX file; a version in JATS XML format.

Please note that the references in this demo are embedded in the docx file, thus pandoc-citeproc is not used.
