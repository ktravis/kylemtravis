---
name: Blog Comments With GitHub
slug: blog-comments
published: 2020-09-09
labels: meta
previewLines: 3
---

_For more background, see my [previous post](https://kylemtravis.com/blog/blogging-with-github) about GitHub Actions._

Now that it's possible to follow the blog and be notified by [watching on GitHub](https://github.com/ktravis/kylemtravis), I wanted to incorporate a little more interactivity. As much as anyone enjoys shouting into the void, I do like the idea of getting feedback - so it's time to incorporate comments.

I follow a [gamedev blog](https://github.com/a327ex/blog) on github that uses issues for posts, which seems like a pretty elegant solution to me: you get comments, reactions, labels, and search "for free". Plus, issues are written in markdown, which is already the format this blog uses for posts (mostly - foreshadowing). I wanted to maintain the independence of the static site, so that means mirroring each post to a GitHub issue, and then displaying comments on the site by retrieving them from GitHub's API.

### Making Issues

Using another GitHub action, we can sync the contents of the `./src/blog/` directory with the repo's issues. At some point in the distant past when writing the static site generator, I decided to use `@key = value` lines in the markdown to set page metadata (which is then used during generation). I don't know why I did this, really. This has the side effect of including the metadata assignments in the rendered page if I don't strip them out while processing, but since the format is simple it's a quick adjustment. I'm probably going to go in and change those out for markdown "comments", i.e. `[//]: # (key = value)` which is a [creative use of link labels](https://stackoverflow.com/a/20885980) - but it works for now.

The steps of the action boil down to:

- checkout the repo
- grep the blog directory for name metadata, writing it to a file
- in the `github-script` step, read the files corresponding to posts and create (or update) issues - applying labels based on metadata

Here is the complete action, and as before, I'm not responsible if my terrible JavaScript gets you fired/burns your house down:

```yaml
name: blog-post-create-issues
on:
  push:
    branches: [ master ]
jobs:
  create:
    runs-on: ubuntu-latest
    steps:
    - name: checkout
      uses: actions/checkout@v2
    - name: collect-titles
      run: "grep -E '@name\\s*\\=' ./src/blog/ -R > posts.txt && cat posts.txt"
    - uses: actions/github-script@v3
      with:
        github-token: ${{secrets.GITHUB_TOKEN}}
        script: |
          const fs = require("fs")
          const { owner, repo } = context.repo
          const result = await github.issues.listForRepo({ owner, repo })
          const issues = Object.fromEntries(result.data.map(x => [x.title, x]))
          let lines = fs.readFileSync('posts.txt').toString().split('\n')
          lines.forEach(l => {
          	l = l.trim()
          	if (!l) return
            let [f, nameLine] = l.split(':')
            let labels = ["blog-post"]
            const body = fs.readFileSync(f).toString().split('\n').map(x => {
              if (x.match(/^\s*@labels/)) {
                labels = labels.concat(x.trim().slice(x.indexOf('=')+1).split(",").map(l => l.trim()))
              }
              return x
            }).filter(x => !x.match(/^@/))
              .join('\n')
              .replace(/(!\[[^\]]*\]\()(\/[^\)]+\))/g, "$1https://github.com/${owner}/${repo}/raw/master$2") // MD image
              .replace(/(\[[^\]]*\]\()(\/[^\)]+\))/g, "$1https://github.com/${owner}/${repo}/blob/master$2") // MD link
              .replace(/(src=")(\/[^"]+")/g, "$1https://github.com/${owner}/${repo}/raw/master$2") // <img> tag
            const title = nameLine.slice(nameLine.indexOf('=')+1).trim()
            if (title in issues) {
              const found = issues[title]
              github.issues.update({
                owner, repo,
                issue_number: found.number,
                labels: found.labels.concat(labels),
                title, body,
              })
              return
            }
            github.issues.create({ owner, repo, title, body, labels })
          })
```

The only notable pieces are the three `replace` calls run on the file contents - if I leave relative links and images like `![caption](/static/foo.png)`, they will break when inserted into a github issue. Instead, since we know relative static content will exist under `https://github.com/${owner}/${repo}/`, we can link to the appropriate `/blob` or `/raw` page. The same is done with image tags. This probably isn't a 100% foolproof or robust solution, but since I'm still in control of the source it just needs to be _good enough_ to avoid broken links.

![an example goat](/static/images/blog/blog-comments/goat.jpg)
_this image link is modified in the created issue_

### Displaying Comments

So now we have a way for readers to comment on (and react to) posts, but needing to leave the site to see these comments defeats the purpose. I initially wrote a JavaScript snippet using [octokit](https://github.com/octokit/rest.js) to pull comments from the associated issue, create DOM elements, and shove them in a div at the bottom of the page. For such a rudimentary solution, it worked pretty well.

The main drawback of the putting a simple custom script on the page is that the reader has to leave in order to submit a comment. While researching options I stumbled on [utteranc.es](https://utteranc.es) which is fantastic, and as you can see below, what I ended up using. The app is extremely easy to integrate with a GitHub repo - I could have omitted the action above and relied on utteranc.es to generate issues for me, but the current method does give me a bit more control over the issue body. The simplicity of [the setup instructions](https://utteranc.es) speaks for itself - just add the GitHub app to the repo and a script tag to the page.

### Takeaways

- You don't have to rely on canned solutions, it's often fulfilling (and fun!) to roll your own if the task is simple enough
- ... that said, sometimes you find an elegant premade solution like [utteranc.es](https://utteranc.es) - don't succumb to [NIH syndrome](https://en.wikipedia.org/wiki/Not_invented_here)
