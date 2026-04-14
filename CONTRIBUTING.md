# welcome

contributions are welcome, doing too strict and legalese things are not my stile
however a couple guidelines are in order.


# guidelines

First and foremost, be respectful, don't be toxic, write and talk in the manned
you'd like to be talked to, now this sounds obvious but it may not be, altho i
run things in a very informal way and recognize that internet language is what
it is which is an extension of informal vulgar english try to keep your typing
of uppercase "FUCK", "FUCK YOU", "PIECE OF SHIT", etc... directed at the code
rather than the individuals writing it, same applies to documentation, if ya
want to write your gamer words which would be at home in 2009 xbox live voice
chat, league of legends chat, or just a call of duty lobby then have the full
expression of your freedom of speech at a suitable platform like 4chan, the
fediverse, your home, voice chat with your friends or any freeze peach platform
ya can find which ain't this, this is a git forge, so unless it is code,
documentation, issues or direct discussion of the software then it doesn't
belong in here, that includes talks of broader politics, i could not care any
less in here about what you think of bubba's glory hole, this is not the
platform to verbally fellate him or call him JE's island cumrag, please go
to another place for that, that ranty verbarrhea aside.


## general

When a piece of software that is not shed is involved please be explicit, i have
no way of knowing what every piece of software is from name alone, even if it
seems obvious just the act of providing a link to the software's homepage in the
first mention is help enough


## issues

When opening an issue please provide detailed information, not just a dry "it
does not work" or a "the documentation is wrong", be specific, add information
about the relevant software like names and versions, the version of shed you are
using down to the commit hash (full hash is not needed), related config files
for shed and the sofware involved.


## pull requests

Follow the 1 feature per pull request convention, ideally every pull request is
related directly to 1 feature, say you want to improve logging and also add some
feature that depends on the improved logging, you may feel tempted to put both
of those in the same Pull Request like "improved logging and feature" but please
do not, even if you got the code all ready to merge just open 2 pull requests,
first "improved logging" and then "feature", in the comment for the "feature"
pull request just specify it depends on "improved logging", this helps keeping
the code and commit history cleaner.


## follow the ai policy

On all interactions from opening issues to submitting code please follow the ai
policy.


# ai policy

## foreword

First and foremost it is important to outline, "Artificial Intelligence" is a
tool, nothing more nothing less, and like every tool there will be people whom
can use it to great extents and those whom completely miss the point and use it
wrong be it from incompetence or malice.

## usage classifications

For the sake of transparency and openness we classify the usage of GenAI for
contributions in the following manner:

- No AI: prospect contributions done completely by humans without the usage of
  large language models, agentic ai, neural networks, neural syntactical
  analizers, autonomous language model lexers, prompt driven code generators.

- AI Assisted Human: prospect contributions created with the assistance of
  generative AI tools in which the majority of the work is still done by a
  human.

- AI Co-Authored: prospect contributions created with the assistance of
  generative AI tools in which a similar or at least equitative part of the work
  was done by a human and a generative AI tool.

- Human Assisted AI: a prospect contribution created with generative AI in which
  the majority of the work was done by the AI and a minority done by a human.

- Agentic AI: a prospect contribution in which the totality of it was generated
  by a type of autonomous or semi-autonomous llm or neural network based system
  in which the human interaction is limited to prompting.

The reasons for the specific wording on these classifications is so that systems
such as code completion, code template completion, language servers, lexical
parsers like tree-sitter, text editors like neovim or emacs will not count as
usage of AI tools as they are NOT, in the side of agentic ai the wording should
suffice so that systems like debian-janitor and lintian won't be considered as
agentic ai.

## usage disclosure and vouching

With the 5 classifications we got for the different levels of ai tools usage we
can define the guidelines for AI usage disclosure and vouching as well as the
thresholds for what enter where.

### No AI

Nothing to ruminate about here, if the prospective contribution has 0% changes
created through AI tools it falls in this cathegory.


### AI Assisted Human

Starting with this cathegory all usage of AI tools for minimal to seemingly
inconsequential it may be starts at this cathegory so long as the AI tool of
choice served as something more than just a fancy code template generator it
goes in here, however not every usage of AI is significative enough to really
bother with outspoken on front disclosure, so in being lenient i will set the
threshold for disclosure of AI assistance at 1/5th or 23% (0.23, i'm being more
generous than IEEE 754 on what constitues ONE FIFTH) of the changes per commit,
once 23% of the changes in an individual commit come from an AI tool it is
required to disclose them as "AI Assisted" and tag the ai model as a co-author
in the commit message, for example if google's gemini was used the last lines of
the commit message ought to look like:
```commit
AI Assisted
Co-authored-by: Gemini <gemini-code-assist@google.com>
```


### AI Co-Authored

In following with the previous cathegory we consider that a commit was
co-authored by an AI tool once the final percentage of changes in the commit
that are authored by an AI tool surpases 1/3rd or 35% (0.35, again i'm being
generous here for the sake of generosity) of the code, with an upper threshold
of 65%, so once the AI provided changes in a commit hit the 36% mark but do not
surpass 65% the prospective contributions shall be tagged as "AI Co-Authored" at
the end of the commit message, again using google's gemini for the example:
```commit
AI Co-Authored
Co-authored-by: Gemini <gemini-code-assist@google.com>
```


### Human Assisted AI

Once the amount of human contributed changes in the commit fall below 35% or in
other words once the AI contributed changes surpasses the 65% threshold the
commit shall have the AI tool as author, be tagged as "Human Assisted" and be
co-authored by the human at the end of the commit message submitting it, in
order to keep things fair and consistent for this case with the "AI Assisted
Human" once the human contribution to the total of the commit's changes fall
below 23%, which is 22% or less of the changes came from a human it is no longer
necessary to tag the human submitter as a co-author, that said this is an
example of what a commit message may look like where the human contributed
around 34% of the total changes, again using gemini AI as the example AI tool:

```commit
Author: Gemini <gemini-code-assist@google.com>
Date:   Sat Apr 18 15:26:07 2026 -0300

Improved lockfile management

This reduces potential race conditions.

Human Assisted
Co-authored-by: Jane Doe <jdoe@tf2mann.co>
```


### Agentic AI

This cathegory being reserved for prospective contributions with 0% human
provided changes, if the only interaction done by the human submitting it was a
prompt then it befalls this cathegory, of course if the prospective contribution
is being submitted by an AI agent it also befalls this cathegory, proper
disclosure and vouching of the changes by a human whom can provide evidence of
having tested the changes is required before the prospective contribution can be
considered for merging.


## Failure to comply

Failure to comply to the AI policy will instill the following consequences:

- Written warning: if a submitted contribution is suspected to not comply with
  the disclosure guidelines of the AI policy a public written warning will be
  issued at the pull request where the contribution was submitted asking the
  submitter for disclosure and clarification on AI tool usage.

- Pull Request Closure: if the submitter fails to comply with the AI policy by
  refusing to disclosure evident use of AI assistance the Pull Request will be
  closed.

- Removal of undisclosed code: if a piece of code was merged which is later
  discovered or suspected to have been AI generated or simply AI assisted but
  without the proper disclosure, said code will be removed and a written message
  issued at the pull request where the contribution was submitted.

- Ban from Contributing: i believe in multiple opportunities to amend mistakes
  so this is a last resort, but prospective contributors whom continuosly fail
  to disclose their usage of AI tools and refuse to change their behaviour will
  be forbidden from contributing to the project.
