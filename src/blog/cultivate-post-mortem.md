@name = Cultivate Post-Mortem
@published = 2016-01-03

Hello there! With just over a day remaining in the voting period, it seemed like a great time to finally write up a post-mortem for my experience this time around. I've included my favorites/recommendations of the entries that I've played so far **at the end of this post.**

**Of course, if you haven't played the game yet I would *love* to get your feedback! Visit the [game page here](http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=28426).**

<div class="captioned-center-image"><img src="/static/images/blog/cultivate-post-mortem/ld48-preview.gif"><p class="caption"><a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=28426">Cultivate is an adventure/visual-novel-like game about a day of high school.</a></p></div>

## Overview

This was a really interesting Ludum Dare for me -- the second I've completed an entry for (and the fourth or fifth that I've actively attempted.) The idea of an adventure game with binary choices that lead to branching paths seemed like it might easily get out of hand and too ambitious for the compo, but I wanted to attempt it anyway. If nothing else, it would be an exercise in limiting scope -- something I usually struggle with in game design.

Ultimately I ended up with an entry that I'm really proud of: despite a few issues it feels reasonably complete (though I would have been pleased to add music!), and represents the original concept well.

## Inspiration

My main inspirations for Cultivate were (in no particular order):

- [Life is Strange](http://store.steampowered.com/app/319630/) - this one is pretty obvious (and I wouldn't want to hide it). I completed the game recently and adored it -- it was very hard to avoid paying homage.
- [American Dream](https://ded.increpare.com/~locus/american_dream/) by [Increpare](https://twitter.com/increpare) others - another Jam game which I've always admired. Using simple visuals to convey detail is something I'm still working on, and I feel like American Dream does so well. Originally I was planning to write with a similar tone, but ultimately decided against it.
- [Undertale](http://store.steampowered.com/app/391540/) - I haven't played the game yet, but I can imagine that there was some unconscious design inspiration at work, particularly for the visual style.
- Shin Megami Tensei: Persona 4 - I've always liked the way relationships (social links) and stats are handled in the Persona series, particularly 4, and wanted to evoke that as much as possible.

## Story

Overall there are several different "sub-stories" within the game, which are seen based on making different sets of choices. For those interested, I'll outline a couple of them, and their endings, here. **It should go without saying, below there are SPOILERS for the game!**

- Meeting and befriending James
- Helping Nina/Simon
- Getting an academic recommendation
- Befriending Charlotte
- Losing Charlotte
- Finding Charlotte
- Befriending Ellie
- None of the above (alone)

I'm not sure whether anyone has seen some of them yet, so if you play I'd love to hear your experience!

**End SPOILERS**

## Tools

- **Unity** - The majority of the games I have completed in the past used Haxe, but lately I've been trying to get acquainted with Unity -- which is a natural fit for game jams given how well it facilitates fast prototyping. I've never finished a project in Unity, which led to some confusion during the export steps, but the rest of the experience was smooth and enjoyable. I have limited C# experience, but with Java and C++ familiarity it didn't seem too hard to grasp the basics.
- **Paint.NET** - I briefly attempted a more "painterly" art style, before deciding on something more simplified. The main reason for this was time -- I had to crank out all of the "background" art for the game in less than 2 hours. Second, I wanted something stylized that left most of the detail to the player's imagination. Ultimately I am pleased with the outcome, though I had planned to create more variety.

<div class="center-image">
    <img src="/static/images/blog/cultivate-post-mortem/cultivate-1-550x413.png" />
</div>

- **[BFXR](http://www.bfxr.net/)** - An amazing tool for generating 8/16-bit sound effects. Use it!
- **The font [Runescape UF](http://www.dafont.com/runescape-uf.font)** - It took a while to found one that I liked, this one was definitely my favorite!

## Technical

**If you are interested, I hosted the source in a [GitHub repository](https://github.com/ktravis/Cultivate). I encourage you to check it out!**

I spent most of my 48 hours programming the components that script the scenes of the game. The design I went with was almost like a domain-specific language in itself for representing a (non-linear) scene within the game's story as a C# Dictionary of "Action" objects, which the engine would iterate over, performing the appropriate functions. With more time I think I would have looked for a more elegant way to write and parse these scripts, but given the reality of the time crunch I had to go for what would allow me to write the story quickly, and provide the bare minimum of functionality (I had a very hard time avoiding feature creep here -- it was easy to get excited about an idea and start refactoring to implement it).

A snippet of a scene from [the script](https://github.com/ktravis/Cultivate/blob/master/Assets/Scripts/Scenes.cs) like this:

```c#
{ "waking", new Scene(
                SET.TIME(0800),
                SET.BG(""),
                SET.MSG("( ... )"),
                A.WAIT(),
                SET.MSG("( you can hear the most horrible sound )"),
                A.WAIT(),
                SET.MSG("*BZZZT* *BZZZT* *BZZZT*"),
                SET.CHOICES(
                    new Choice("Snooze...", INC.TIME(0010)),
                    new Choice("Open your eyes, turn it off", A.GOTO("awake"))
                ),
                SET.MSG("( ... )"),
                A.WAIT(),
                SET.MSG("*BZZZT* *BZZZT* *BZZZT*"),
                SET.CHOICES(
                    null,
                    new Choice("Open your eyes, turn it off", A.GOTO("awake"))
                ),
            A.LABEL("awake"),
                SET.BG("waking-up"),
                SET.MSG("Ah, another fine school day. ( you urgently need the restroom )"),
                A.WAIT(),
                SET.SCENE("bathroom")
    ) }
```

It ends up looking a bit like Assembler-style directives, that block and branch at calls to "SET.CHOICES(...)" based on the player's response. I use a very simple system of "labels" to jump (i.e. "GOTO" places in the script). Not shown here are the stats which are stored in a dictionary and modified via "SET" and "INC", as well as conditional actions, which will branch based on the values of those stats. This allowed me to do things like change a line of dialogue, or an entire scene, based on the player's "empathy" stat, for example.

This system has a fair number of limitations, but it did allow me to write the story quick enough to finish in time. The entire [scenes file](https://github.com/ktravis/Cultivate/blob/master/Assets/Scripts/Scenes.cs) contains almost 1200 lines of these actions which I spent most of the second day writing. Needless to say, my hands were a bit tired by the end of the compo!

## Roundup

##### The good:

- Unity! Once I got my workflow figured out it was smooth sailing during development. It was particularly straightforward to export from Paint.NET into my assets folder, and pull the images right into my scene in Unity for use. The only things I wasn't pleased about were using C# (more of a neutral than negative, I would have preferred to use a language I was more comfortable with), and the final export of the game, which I will get to in a moment...
- I am pleased with the story itself, and player's reactions to it so far. I am not very confident with my ability to write fiction (especially quickly), but people seem to like it.
- The art style was something new for me (most of my games in the past have used simple geometric shapes), and I think it turned out close enough to what I envisioned while still being easy to generate.

##### The bad:

- Exporting my project from Unity (though I would attribute most of this to being rushed, and having little-to-no experience with the process.) I decided early that the main target would be WebGL so that the game could be played in a browser without plugins. This was mostly smooth, but I'm still not pleased with how the Unity WebGL framework seems to lock up the entire tab while the game loads initially. It could be something I'm doing (I would be happy to know if it was), but I've noticed it with other WebGL-target entries as well. Aside from that the performance is good, but debugging is quite difficult and I've had a few issues introduced that are not present in the editor build.I was intending to build Windows/OSX/Linux standalone binaries, but during the submission hour I quickly realized this wouldn't be feasible. For some reason I couldn't get the Windows build to lock its resolution, which caused all of the game objects with a CanvasRenderer to scale wildly and end up in the wrong positions. I believe this was probably due to my inexperience, and had I configured these appropriately to begin with (or checked the standalone targets sooner) I wouldn't have run into this issue, but as it stands with my current knowledge the scaling is too heavily entrenched to be easily remedied without causing other issues.
- I was really hoping to get at least one simple loop of music done for the game, but it just wasn't possible given how late I finished the art. Perhaps this will come in a future update.

## Recommendations

Overall my favorite part of this Ludum Dare has been playing everyone's entries, I've seen so many that blew me away! The theme(s) really seemed to inspire people this time around. Here are a few that I wanted to mention fondness for -- again in now particular order, and I'm sorry if I've forgotten to include your entry! It's hard to remember all of the amazing games.

<h4><a href="Jam">Fruit Wolf (Jam)</a></h4>
<div class="image-right">
<div>
I love this entry: the style, the concept, the music -- all fantastic!
</div>
<a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=7984"><img class="alignright" src="/static/images/blog/cultivate-post-mortem/7984-shot0-1450145288.png-eq-900-500.jpg" alt="" width="387" height="215" /></a>
</div>

<h4><a href="Jam">Grow Your Love (Jam)</a></h4>
<div class="image-right">
<div>
Another amazing interpretation of the themes. I can't overstate how charmed I was by the aesthetic and music -- though it should be mentioned how cleverly the gameplay is designed. Even for the Jam, I am amazed by the level of polish here.
</div>
<a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=7285"><img class="alignright" src="/static/images/blog/cultivate-post-mortem/7285-shot0-1450286764.png-eq-900-500.jpg" alt="" width="387" height="218" /></a>
</div>

<h4><a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=51259">Acrodog</a></h4>
<div class="image-right">
<div>
Adorable, challenging and addictive. This was another entry that seemed to naturally fit within the theme while feeling very unique.
</div>
<a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=51259"><img class="alignright" src="/static/images/blog/cultivate-post-mortem/51259-shot2-1450059185.gif" alt="" width="389" height="243" /></a>
</div>

<h4><a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=10217">Tamamystery</a></h4>
<div class="image-right">
<div>
I don't think I can accurately describe this one, other than to say it was very clever! Lots of nostalgia, and a very complete experience.
</div>
<a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=10217"><img class="alignright" src="/static/images/blog/cultivate-post-mortem/10217-shot3-1450061837.png-eq-900-500.jpg" alt="" width="220" height="270" /></a>
</div>

<h4><a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=18943">The Serpent's Shadow</a></h4>
<div class="image-right">
<div>
Created for/with <a href="http://www.lexaloffle.com/pico-8.php" target="_blank">Pico8</a>, this is a fantastic puzzle game with a great visual style, music, and a puzzle-solving mechanic that feels really innovative.
</div>
<a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=18943"><img class="alignright" src="/static/images/blog/cultivate-post-mortem/18943-shot2-1450053737.png-eq-900-500.jpg" alt="" width="331" height="331" /></a>
</div>

<h4><a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=15514">Initial Conditions</a></h4>
<div class="image-right">
<div>
A deceptively simple puzzle game. Overall this entry had excellent design, and some really challenging levels. Beyond that, it even incorporates impressive voice-acting between puzzles.
</div>
<a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=15514"><img class="alignright" src="/static/images/blog/cultivate-post-mortem/15514-shot1-1450058247.png-eq-900-500.jpg" alt="" width="387" height="274" /></a>
</div>

<h4><a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=22357">Nomads</a></h4>
<div class="image-right">
<div>
Moving and minimalist. Attempts a different type of game that fits the theme well, and succeeds in being captivating (to me, at least!)
</div>
<a href="http://ludumdare.com/compo/ludum-dare-34/?action=preview&amp;uid=22357"><img class="alignright" src="/static/images/blog/cultivate-post-mortem/22357-shot0-1450146808.png-eq-900-500.jpg" alt="" width="387" height="290" /></a>
</div>

Though there were many others I played and greatly enjoyed, this list is already getting quite long! If you have an entry I haven't commented on, link it in the comments, I'd love to see it!

Thank you for reading, and making this LD awesome. Happy New Year!
