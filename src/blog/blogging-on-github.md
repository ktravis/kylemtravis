@name = Blogging With GitHub
@published = 2020-08-28

_Obligatory "wow it's been so long since I've written here!"_

In an effort to reduce the (admittedly already low) friction of writing blog posts, I'm now hosting this site on
[netlify](https://netlify.com), which makes it pretty effortless to generate site previews off of pull requests, as well
as perform the usual tasks like updating DNS, provisioning a Let's Encrypt cert, etc. I'm still using [my own static
site generator](https://github.com/ktravis/ssgen) which was easy to integrate with netlify's GitHub App: I set my site's
"build command" to `make build`, which runs:

```make
SSGEN_BIN ?= ./ssgen

build: $(SSGEN_BIN)
	$(SSGEN_BIN) -in src -out build
	cp -R static/ build/

$(SSGEN_BIN):
	go get github.com/ktravis/ssgen
	go build -o $@ github.com/ktravis/ssgen
```

netlify will then publish static content in the `build/` directory.

I wanted to make the process of publishing a new blog post feel a bit more dynamic by allowing people to "follow" and be
notified of new posts (this is probably a bit optimistic, but I'm mostly interested in the technical challenge). Since
the site's source is already hosted on GitHub, it seems natural that _watching the repo_ should give you that
notification. Rather than spamming people with notifications on every commit, I'd like interested parties to be able to
watch "releases only" - meaning I need to create a new release when a new blog post is added. Simple enough, but why do
that manually when we can automate it?

A quick dive into the world of GitHub Actions led me to [actions/github-script](https://github.com/actions/gihub-script)
which allows easy use of the Octokit API directly from a workflow definition - i.e. without creating your own custom
action. After a bit too much trial and error (thanks JavaScript) I ended up with this:

```yaml 
# .github/workflows/release.yml
name: blog-post-release
on:
  pull_request:
    branches: [ master ]
    types: [ opened, edited, closed, reopened ]
jobs:
  announce:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/github-script@v3
      with:
        github-token: ${{secrets.GITHUB_TOKEN}}
        script: |
          const pr = context.payload.pull_request
          if (pr.state !== "open" && pr.merged_at === null) {
            console.log("pr was not merged, skipping")
            return
          }
          let urlBase = "https://kylemtravis.com/blog"
          if (pr.state === "open")
            urlBase = `https://deploy-preview-${pr.number}--kylemtravis.netlify.app/blog`
          const result = await github.pulls.listFiles({
            pull_number: pr.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
          })
          const added = result.data.filter(f => f.status === "added")
          const newBlogPosts = added.filter(f => f.filename.match(/src\/blog\//) !== null)
          if (newBlogPosts.length < 1)
            return
          const releaseName = newBlogPosts[0].patch.match(/@name\s*=\s*(.+)/)[1]
          let slug = releaseName.toLowerCase().replace(/\s+/g, "-").replace(/[^a-zA-Z0-9\-]/g, "")
          const slugMatch = newBlogPosts[0].patch.match(/@slug\s*=\s*(.+)/)
          if (slugMatch && slugMatch.length > 1)
            slug = slugMatch[1]
          const rel = {
            owner: context.repo.owner,
            repo: context.repo.repo,
            tag_name: `blog-pr-${pr.number}`,
            target_commitish: pr.head.sha,
            name: `[Blog Post] ${releaseName}`,
            body: `New blog post, read it [here](${urlBase}/${slug})!`,
            draft: pr.state === "open",
          }
          const rels = await github.repos.listReleases({
            owner: context.repo.owner,
            repo: context.repo.repo,
          })
          const found = rels.data.filter(r => r.draft && r.tag_name == rel.tag_name)
          await (found.length > 1 ?
            github.repos.updateRelease({
              release_id: found[0].id,
              ...rel
            }) :
            github.repos.createRelease(rel)
          )
```

That's it - the whole deal. It's more verbose that it needs to be, because a) my js is not great, and b) I have some
metadata in the contents of the blog post that I wanted to pick out. The result is an action that will run on pull
requests, creating or updating a release if that PR *adds* files under the path `./src/blog/`. A PR that only changes
existing posts will not trigger a new release, and a draft release is created (pointing to the netlify preview) if the
PR is yet to be merged. One loose end, closed PR's will leave behind a draft release. This could easily be fixed with a
bit more logic, but I am happy with the tradeoff for now.

I'm convinced this solution could be made even simpler, but rather than prematurely optimize, I'm going to leave it
as-is for now; after all, it's no good if it's not being used yet.

Thank you for reading - if you're interested in following along, you can [watch the repo
here!](https://github.com/ktravis/kylemtravis)
