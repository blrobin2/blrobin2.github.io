---
layout: post
title: "CSS, Part 1: Typography"
excerpt: "After enough procrastination (and some genuine thought), I talk about CSS, and why I changed it around so much."
category: web
---

I'm going to assume there is <em>a</em> reader out there who may or may not have visited the site between the last article and this one. If so, that person saw a complete theming of the site in various shades of blue, a goofy logo, and lots of little details. I kept it that way for a good while, thinking I would just refine that as time goes on.

But, the more I looked at it, the more I hated it. And I realized that, while I had a look that was fairly unique, it didn't look <em>designed.</em> So, I went back to the books, and decided to focus less on code and development and more on design. Because I am a designer by trade, and if my personal tricks that I use for clients isn't working for me, it probably won't work for my clients much longer.

### Web Design 101
Hold up, don't run yet. I actually have very little to say on this subject, and more references that have a much better way of stating it. We're venturing into an area that is highly opinionated and diverse. Feel free to disagree with me, but understand that what I'm about to say is not &ldquo;The Rules,&rdquo; but what guided the CSS that exists on the site presently.

The first, and most important thing to understand about web design is that [the web is 95% typography](http://ia.net/blog/the-web-is-all-about-typography-period). What I mean by this is that the web is made up predominantly of text, and should therefore be our primary concern. Go to any site you visit regularly and remove the text, and see what remains. Now, unless you regularly visit a site that hasn't updated since 2008, you will see... very little (sorry 2008, but you were all about some torn paper and layouts built on images). A line here, some images, a block of color there, <em>maybe</em> some textures. On some sites, such as the one reference above, you may see almost nothing at all.

What we're seeing these days are a lot of designers who are reeling back and remembering this, and changing their design aesthetic accordingly. Even Apple thought they should cut out some of the noise with [iOS 7](http://www.apple.com/ios/ios7/) ([opinions](http://mattgemmell.com/2013/06/12/ios-7/). [opinions](http://www.computerworld.com/s/article/9240307/Why_I_hate_the_look_and_feel_of_iOS_7?pageNumber=1), [everywhere](http://dribbble.com/shots/1109343-iOS-7-Redesign)). But that's another article, and one that I don't want to write. At all.

The important thing to note is that typography is finally moving into an arena where we can treat it better, and treat our clients better with easy to read, elegant typography.

Now, I'm not saying I think my design is &ldquo;elegant,&rdquo; necessarily. But compared to what came before, I believe this is a lot better. With this principle in mind, I have two resources to thank for the current look and feel of this site:

###[The Elements of Typographic Style Applied to the Web](http://webtypography.net/)

This eBook has been around for ages. I've looked at it over and over, and every time I've gone to it, I've thought, &ldquo;Yeah, maybe if I write articles online, but that's never going to happen&rdquo; (Is this irony?). In this book are ways of approaching the rules of [The Elements of Typographic Style](http://www.amazon.com/Elements-Typographic-Style-Robert-Bringhurst/dp/0881791326) in CSS. Some of the considerations are looking like they won't pan out, such as CSS3 Kerning support, but for the most part, there are some good ideas here that are worth considering, regardless of the type of content you serve on the web.

###[Typecast](http://typecast.com/)

Typecast is an online tool for testing out and deploying web typography. It is here that I developed the look the site current has, emphasizing contrast, color, and vertical rhythm. Don't know what that means? There's a book online about typographic style... I initially set up [five different samples](http://typecast.com/XWCQHb-zz4/share/38a9700d0271fd4acbda9b69028afd845724ae22Q7N), and asked some friends and co-workers which ones they found the most readable. Based on their input, I did a final draft, to which I added some additional colors to give the look a little personality. The result is this page.

###CSS Preprocessors

For the previous look of the site, I used a preprocessor called [<abbr title="Syntatically-Awesome Style Sheets">SASS</abbr>](http://sass-lang.com/) to organize my code. I have not abandoned SASS, and will likely re-organize the site using it, after which I will write more about it. Honestly, I became so excited when I finished the final draft that you see, I couldn't wait to get it up on the web.

Which means that I have not synced it with Github yet. But, if you really want to see what I have, you can view source and click on the CSS file. As for the architecture of the site, very little has changed other than the addition of classes. For the next article, I will get everything synced up.

That's it for now (told you it wouldn't be bad). Next time, we'll focus on SASS.