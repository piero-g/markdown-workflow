---
# Please, fill every field carefully. Mandatory fields cannot be left unattended; unused fields must be excluded by removing the corresponding line or commenting it (adding # before the variable)
title: "Article title. A demo article full of gibberish word meant to test the Pandoc solution"
shorttitle: "Article title" # applied in PDF internal pages (optional)

dates: # please follow the example: YYYY-MM-DD;
  submitted: 2017-02-05
  #revised: # multiple values are possible
  accepted: 2017-06-18
  published: 2018-03-01
# in PDF dates will be converted in the current language; If you have only a textual value you can use "date" instead

# be respectful of spacings, the dash identify each authors block
author:
  - name: "Name Surname" # mandatory
    given-name: Name # including second name
    surname: Surname
    affiliation: "Affiliation (country)" # mandatory, country in rounded brackets; multiple affiliations should be listed, see the example below; do not put text outside the upper brackets
    email: "example@email.org"
    corresp: true
    orcid: https://orcid.org/0000-0002-1825-0097 # express it as a full URI, starting with https://
    bio: "This is a short bio, _italics_ and **bold**. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam auctor blandit egestas. Maecenas faucibus eros velit, vitae posuere metus tincidunt et. In vel justo sed ante iaculis facilisis a quis sapien. Nulla lacinia eu massa pharetra sollicitudin. Pellentesque tempor elit sit amet libero fermentum commodo. In hac habitasse platea dictumst. Suspendisse ornare cursus enim in condimentum. Mauris blandit leo metus, quis pretium turpis porta ac. Maecenas placerat metus ac massa condimentum, vitae tristique nunc sagittis. Nullam dapibus in tortor sit amet bibendum. Proin sem libero, porta a pharetra auctor, iaculis at elit." # optional short bio, no more than 100 words; markdown ok, not paragraphs

  # the following is a 2nd author block; please add as many copies of this block as the number of authors. Note the absence of "corresp" parameter
  - name: "Name Surname" # mandatory
    given-name: Name
    surname: Surname
    affiliation: # this author has two affiliations, listed properly
      - "Affiliation 1 (country 1)"
      - "Affiliation 2 (country 2)"
    email: "example@email.org"

# respect indentation when compiling the abstract; the example below supports italics and multiple paragraphs
abstract: |
  Lorem ipsum dolor sit amet, *consectetur adipiscing elit*. Curabitur in ante lobortis, euismod ligula varius, pellentesque ante. Curabitur suscipit lacus nibh, ut finibus purus -- scelerisque eget. Vestibulum nec enim odio. Sed feugiat metus iaculis, efficitur massa in, pulvinar neque. Donec tellus dui, luctus eu efficitur et, tristique a odio.

  Integer faucibus porttitor eros at finibus.

# same rules as abstract
acknowledgements: |
  Lorem ipsum dolor sit amet, *consectetur adipiscing elit*. Curabitur in ante lobortis, euismod ligula varius, pellentesque ante.

keywords: [Lorem, ipsum, dolor, sit, amet] # keep square brackets and comma separated values

article:
  #doi: # insert the DOI here, without the prefix "https://doi.org/"
  #id: NNNN # optional submission ID / publisher ID
  section: "Essays" # the displayed name of the article section
  type: "article" # possible options are: `article`, `editorial`, `review`, `book-review`
  peer-review: true

copyright:
  holder: "Name Surname, Name Surname" # mandatory
  year: 2018 # mandatory
  type: open-access # journal based, do not edit
  text: "This work is licensed under the Creative Commons BY License."
  link: https://creativecommons.org/licenses/by/4.0/ # journal based, do not edit

# language
lang: en-US # mandatory: en-US, en-GB, it-IT...

# page numbering
page:
  prefix: draft # uncomment and fill if you need a prefix for the page sequence (eg: reviews could use a "p. R 12")
  #roman: true # uncomment if you need the page numbers in Roman numbers, eg: for Editorial; change to "romanup" for UPPERCASE roman numbers
  start: 1 # edit to determine the starting page for this article

# set to true to avoid the page break after title / abstract / author info
notitlepage: false

# set to true to avoid author blocks, affiliation will appear in footnote
affiliationonly: false

# Table of Contents: set to "false" if there should be no Table of Contents in HTML (eg: few and short sections)
toc: true
---
Demo Article

John Doe

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce sit amet elit ut enim commodo ultricies a nec sapien. Sed blandit hendrerit luctus. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi condimentum non risus nec tempus.

# 1. First section with formatted text

*This sentence is in italic*. Vestibulum ante ipsum primis in **a few bold words (strong emphasis)** faucibus orci luctus et ultrices posuere cubilia Curae; here we have a hard breakline.\
No new paragraph was created. In auctor pulvinar auctor. Vivamus nulla lectus, elementum vitae tellus quis, volutpat iaculis tellus.

Here we have a new paragraph. Nulla eget porttitor leo.[^1] Ut cursus ultrices augue in commodo. Nulla in est tellus. Nam ac massa at dolor cursus hendrerit quis id orci. Nam nec erat eget dolor mattis facilisis nec et risus. Aenean mattis erat ac nisl tincidunt pharetra.[^2]

## 1.1 Subsection with quotations

Ut vulputate, neque vitae accumsan luctus, risus lorem molestie sapien, ut vehicula magna diam et dolor.

> This is a long quotation made with a simple "Increase left indent." In a libero eu arcu auctor blandit sed quis dui. Nam feugiat ultricies ligula quis scelerisque. Nulla facilisi. Vivamus rutrum ante eros, ut elementum est consequat elementum. Vivamus commodo libero facilisis, suscipit risus vel, egestas felis.

Integer sollicitudin eleifend neque, vitae faucibus magna consectetur nec. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; on the other hand "this is a short quotation."

# 2. Second section

## 2.1 Different languages

This is just some dummy text for testing purposes. This is a greek word: χάρισμα, while the next quotation is in Italian.

> Due uomini stavano, l'uno dirimpetto all'altro, al confluente, per dir così, delle due viottole: un di costoro, a cavalcioni sul muricciolo basso, con una gamba spenzolata al di fuori, e l'altro piede posato sul terreno della strada; il compagno, in piedi, appoggiato al muro, con le braccia incrociate sul petto.

## 2.2 Images and tables

Quisque placerat, diam eget maximus mattis, ipsum risus dignissim nisi, id rutrum ipsum augue a tortor. Integer quis fringilla odio. Interdum et malesuada fames ac ante ipsum primis in faucibus.

![](media/image1.jpeg){width="6.6930555555555555in" height="2.86875in"}

Figure 1: a short caption for the image

Quisque sit amet ligula ut nulla ultrices dictum. Nulla non hendrerit erat, nec dictum dolor. Integer quis augue nec neque posuere luctus non eu massa. Cras diam diam, dictum dignissim turpis et, imperdiet vestibulum ipsum.

                 **Column A**   **Column B**
  -------------- -------------- --------------
  *First Row*    Cell 1A        Cell 1B
  *Second Row*   Cell 2A        Cell 2B

  : Simple Table

Aliquam eget sapien laoreet velit placerat ornare. Vivamus tempor a eros id volutpat. Aliquam blandit vitae felis pretium pretium. Nulla lobortis imperdiet nisi, nec tincidunt neque tempus sed. In hac habitasse platea dictumst. Cras suscipit nisi vitae cursus semper.

# 3. Third Section: messy formatting

Different font, different size, different style! Etiam ac fermentum turpis. Nunc id iaculis ipsum. Aliquam in hendrerit nisi, quis lacinia lectus. Sed scelerisque interdum neque, ac ultrices nisi interdum sit amet. Fusce convallis aliquet vehicula.

Various revisions and comments. Pellentesque porta odio porta dui auctor, a viverra nibh sodales. This is a new revision ante semper ipsum ullamcorper blandit. Cras iaculis, nisl et convallis blandit, nulla mi congue urna, et laoreet est nisl quis felis. et metus sed lacinia. Donec consequat ornare urna sed congue.

Different colors and highlights. Cras ullamcorper, eros nec auctor mattis, mauris neque sodales velit, et condimentum augue diam eu nunc. Sed vel malesuada eros. Sed quis ultrices neque, non commodo augue. Maecenas efficitur sapien eget nisi euismod, eu lacinia leo tempus. Ut pretium magna ultricies ultrices fermentum. Mauris ultricies pellentesque consectetur. Proin iaculis mollis dolor, et faucibus tortor. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi eget mollis nisl.

# References

Hisakata, R., Nishida, S., & Johnston, A. (2016). An adaptable metric shapes perceptual space. *Current Biology*, *26*(14), 1911--1915. [[https://doi.org/10.1016/j.cub.2016.05.047]{.underline}](https://doi.org/10.1016/j.cub.2016.05.047)

Hogue, C. W. V. (2001). Structure databases. In A. D. Baxevanis & B. F. F. Ouellette (Eds.), *Bioinformatics* (2nd ed., pp. 83--109). New York, NY: Wiley-Interscience.

Musk, E. (2006, August 2). The secret Tesla Motors master plan (just between you and me). Retrieved September 29, 2016, from [[https://www.tesla.com/blog/secret-tesla-motors-master-plan-just-between-you-and-me]{.underline}](https://www.tesla.com/blog/secret-tesla-motors-master-plan-just-between-you-and-me)

Sambrook, J., & Russell, D. W. (2001). *Molecular cloning: a laboratory manual* (3rd ed.). Cold Spring Harbor, NY: CSHL Press

[^1]: This is a simple footnote;

[^2]: All external links should be placed in footnotes rather than inline, and should be rendered as plain URI, such as the following: [https://pandoc.org]{.underline}
